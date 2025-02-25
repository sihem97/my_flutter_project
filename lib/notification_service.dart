import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User notification settings: ${settings.authorizationStatus}');

    // Configure local notifications
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        // Handle notification tap
      },
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'service_requests', // id
      'Service Requests', // name
      description: 'Notifications for service requests', // description
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Received foreground message: ${message.notification?.title}");
      _showLocalNotification(message);
    });

    // Handle background and terminated state messaging
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint("App opened from terminated state via notification");
        // Handle the initial message when app is launched from notification
      }
    });

    // Log the FCM token for debugging
    String? token = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');
  }

  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint("Handling background message: ${message.messageId}");
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'service_requests',
            'Service Requests',
            channelDescription: 'Notifications for service requests',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            icon: android?.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['type'],
      );
    }
  }

  // Save worker's FCM token with additional metadata
  static Future<void> saveWorkerToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('Saving worker token: $token for user: $userId');

      if (token != null) {
        await FirebaseFirestore.instance
            .collection('workers_fcm')
            .doc(userId)
            .set({
          'token': token,
          'lastUpdated': FieldValue.serverTimestamp(),
          'active': true,
          'platform': defaultTargetPlatform.toString(),
        });

        // Handle token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('FCM token refreshed: $newToken');
          saveWorkerToken(userId);
        });
      }
    } catch (e) {
      debugPrint('Error saving worker token: $e');
    }
  }

  // Notify nearby workers with improved error handling and batching
  static Future<void> notifyNearbyWorkers(
      String service,
      double latitude,
      double longitude,
      double radius,
      ) async {
    try {
      debugPrint('Notifying nearby workers for service: $service within ${radius}km');

      // Get all workers with the matching service
      QuerySnapshot workersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .where('service', isEqualTo: service)
          .get();

      debugPrint('Found ${workersSnapshot.docs.length} workers with service: $service');

      List<String> nearbyWorkerTokens = [];

      // Check each worker's distance
      for (var doc in workersSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('location') &&
            data['location'] != null &&
            data['location']['lat'] != null &&
            data['location']['lng'] != null) {

          double distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            data['location']['lat'],
            data['location']['lng'],
          );

          debugPrint('Worker ${doc.id} is ${distance/1000}km away');

          if (distance <= radius * 1000) { // Convert km to meters
            // Get worker's FCM token
            DocumentSnapshot tokenDoc = await FirebaseFirestore.instance
                .collection('workers_fcm')
                .doc(doc.id)
                .get();

            if (tokenDoc.exists) {
              var tokenData = tokenDoc.data() as Map<String, dynamic>;
              if (tokenData['token'] != null && tokenData['active'] == true) {
                nearbyWorkerTokens.add(tokenData['token']);
                debugPrint('Added token for worker: ${doc.id}');
              }
            }
          }
        }
      }

      debugPrint('Found ${nearbyWorkerTokens.length} nearby worker tokens to notify');

      if (nearbyWorkerTokens.isEmpty) {
        debugPrint('No nearby workers to notify');
        return;
      }

      // Batch notifications in groups of 500 (FCM limit)
      const int batchSize = 500;
      for (var i = 0; i < nearbyWorkerTokens.length; i += batchSize) {
        var batch = nearbyWorkerTokens.sublist(
          i,
          i + batchSize > nearbyWorkerTokens.length
              ? nearbyWorkerTokens.length
              : i + batchSize,
        );

        // Add to notifications queue for processing by Cloud Functions
        DocumentReference queueRef = await FirebaseFirestore.instance.collection('notifications_queue').add({
          'tokens': batch,
          'title': 'New Service Request',
          'body': 'A new $service request is available in your area!',
          'data': {
            'type': 'new_request',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK', // 3. Required for Android intents
            'service': service,
          },
          'timestamp': FieldValue.serverTimestamp(),
        });

        debugPrint('Added notification batch to queue: ${queueRef.id}');
      }
    } catch (e) {
      debugPrint('Error sending notifications: $e');
    }
  }
}