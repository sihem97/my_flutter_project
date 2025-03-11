import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'service_requests',
    'Service Requests',
    description: 'Notifications for new service requests',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  );

  static Future<void> initialize() async {
    await _requestPermissions();
    await _requestPermissions();
    await _initializeLocalNotifications();
    await _setupNotificationChannels();
    _setupMessageHandlers();
  }

  static Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );
  }

  static Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  static Future<void> _setupNotificationChannels() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static void _handleNotificationTap(NotificationResponse response) {
    // Handle notification tap
    if (response.payload != null) {
      final data = json.decode(response.payload!);
      // Implement navigation logic here
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    await _showLocalNotification(message);
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    // Implement navigation logic when app is opened from notification
  }

  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    await _showLocalNotification(message);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }

  // Add the missing updateWorkerToken method
  static Future<void> updateWorkerToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        try {
          // Update token in both collections using a batch
          final batch = _firestore.batch();

          final workerLocationRef = _firestore.collection('workers_location').doc(user.uid);
          final userRef = _firestore.collection('users').doc(user.uid);

          batch.set(workerLocationRef, {
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          batch.update(userRef, {
            'fcmToken': token,
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });

          await batch.commit();
          print('Worker token updated successfully: $token');
        } catch (e) {
          print('Error updating worker token: $e');
        }
      }
    }
  }

  // Add the missing unsubscribeFromService method
  static Future<void> unsubscribeFromService(String service) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('service_$service');
      print('Unsubscribed from service: $service');
    } catch (e) {
      print('Error unsubscribing from service: $e');
    }
  }

  // Method to subscribe to a service
  static Future<void> subscribeToService(String service) async {
    try {
      await _firebaseMessaging.subscribeToTopic('service_$service');
      print('Subscribed to service: $service');
    } catch (e) {
      print('Error subscribing to service: $e');
    }
  }

  static Future<void> sendNotificationToWorkers(
      List<Map<String, dynamic>> workers,
      String requestId,
      String service,
      String description,
      ) async {
    const functionUrl = 'https://us-central1-pleasework-286b5.cloudfunctions.net/sendNotificationToWorker';

    for (var worker in workers) {
      if (worker['fcmToken'] != null) {
        try {
          final response = await http.post(
            Uri.parse(functionUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'token': worker['fcmToken'],
              'title': 'New $service Request',
              'body': 'New request ${worker['distance'].toStringAsFixed(1)}km away: $description',
              'data': {
                'requestId': requestId,
                'type': 'new_request',
                'distance': worker['distance'].toString(),
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              },
            }),
          );

          if (response.statusCode != 200) {
            print('Error sending notification: ${response.body}');
          }
        } catch (e) {
          print('Error sending notification to worker: $e');
        }
      }
    }
  }
}