import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'HistoryScreen.dart';
import 'main.dart';
import 'notification_service.dart';
import 'sign_in.dart';
import 'worker_profile.dart';
import 'contact_us.dart';
import 'accepted_requests_screen.dart';
import 'pending_confirmations_screen.dart';
import 'l10n/app_localizations.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({Key? key}) : super(key: key);

  @override
  _WorkerHomePageState createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  String workerName = "Worker"; // Will be updated from Firestore
  String workerService = ""; // E.g., "plumbing"
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LatLng? workerPosition;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  String _formatTimestamp(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute}";
  }

  @override
  void initState() {
    super.initState();
    _fetchWorkerName();
    _fetchWorkerLocation();
    _fetchWorkerService();
    _setupNotificationHandling();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      NotificationService.saveWorkerToken(currentUser.uid);
    }
  }

  // Fetch the worker's name
  void _fetchWorkerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          workerName = doc.data()!['name'] ??
              AppLocalizations.of(context).translate('worker');
        });
      }
    }
  }

  // Fetch the worker's location
  void _fetchWorkerLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists || !doc.data()!.containsKey('location')) {
        Position position = await Geolocator.getCurrentPosition();
        await docRef.update({
          'location': {'lat': position.latitude, 'lng': position.longitude},
        });
        setState(() {
          workerPosition = LatLng(position.latitude, position.longitude);
          _updateMap();
        });
      } else {
        setState(() {
          workerPosition = LatLng(
            doc.data()!['location']['lat'],
            doc.data()!['location']['lng'],
          );
          _updateMap();
        });
      }
    }
  }

  // Fetch the worker's service type
  void _fetchWorkerService() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          workerService = doc.data()!['service'] ?? "";
          print("Worker service fetched: $workerService"); // Debug log
        });
      }
    }
  }

  // Update the map with the worker's location
  void _updateMap() {
    if (workerPosition != null) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId("worker"),
            position: workerPosition!,
            infoWindow: InfoWindow(
                title:
                AppLocalizations.of(context).translate('your_location')),
            icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
    }
  }

  // Show a dialog for the worker to submit a bid
  void _showBidDialog(String requestId) {
    TextEditingController priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
          Text(AppLocalizations.of(context).translate('your_bid')),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)
                  .translate('enter_your_price'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            TextButton(
              onPressed: () async {
                double? price = double.tryParse(priceController.text);
                if (price != null && price > 0) {
                  await _submitBid(requestId, price);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(context)
                            .translate('enter_valid_price'))),
                  );
                }
              },
              child: Text(AppLocalizations.of(context).translate('submit')),
            ),
          ],
        );
      },
    );
  }

  // Submit a bid for a request
  Future<void> _submitBid(String requestId, double price) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      DocumentSnapshot requestDoc =
      await _firestore.collection('requests').doc(requestId).get();
      if (!requestDoc.exists) return;
      String? userId = requestDoc['userId'];
      if (userId == null) return;
      if (workerName ==
          AppLocalizations.of(context).translate('worker')) {
        final workerDoc =
        await _firestore.collection('users').doc(user.uid).get();
        if (workerDoc.exists && workerDoc.data() != null) {
          workerName = workerDoc.data()!['name'] ??
              AppLocalizations.of(context).translate('worker');
        }
      }
      await _firestore.collection('bids').add({
        'requestId': requestId,
        'userId': userId,
        'workerId': user.uid,
        'workerName': workerName,
        'price': price,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('bid_submitted_successfully'))),
      );
    } catch (e) {
      print("Error submitting bid: $e");
    }
  }
  void _setupNotificationHandling() {
    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received foreground message: ${message.notification?.title}");

      // Show a dialog or snackbar when a new request comes in
      if (message.data['type'] == 'new_request') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).translate('new_request_available'),
            ),
            action: SnackBarAction(
              label: AppLocalizations.of(context).translate('view'),
              onPressed: () {
                // Refresh the list to show the new request
                setState(() {});
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });

    // Handle when app is in background and user taps on notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Opened app from background message: ${message.notification?.title}");
      if (message.data['type'] == 'new_request') {
        // Refresh the list to show the new request
        setState(() {});
      }
    });
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const int R = 6371; // Earth's radius in km
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) *
            cos(lat2 * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in km
  }

  @override
  Widget build(BuildContext context) {
    // Wait for workerService to be fetched before building the UI.
    if (workerService.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).translate('home')),
          backgroundColor: Colors.red.shade800,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('home')),
        backgroundColor: Colors.red.shade800,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Colors.red[800],
              height: 120,
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('menu'),
                  style: TextStyle(color: Colors.white, fontSize: 30),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(AppLocalizations.of(context).translate('profile')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WorkerProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in),
              title: Text(AppLocalizations.of(context)
                  .translate('accepted_requests')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AcceptedRequestsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_bottom),
              title: Text(AppLocalizations.of(context)
                  .translate('pending_confirmations')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                      const PendingConfirmationsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(AppLocalizations.of(context).translate('history')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title:
              Text(AppLocalizations.of(context).translate('contact_us')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ContactUsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(AppLocalizations.of(context).translate('logout')),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SignInScreen(MyApp.of(context).setLocale)),
                );
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('requests')
            .where('status', isEqualTo: 'pending')
            .where('service', isEqualTo: workerService) // Filter by worker's service
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          print("Fetched Requests: ${snapshot.data!.docs}");
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final request = snapshot.data!.docs[index];
              final String userId = request['userId']; // Get client ID

              return FutureBuilder<DocumentSnapshot>(
                future:
                _firestore.collection('users').doc(userId).get(), // Fetch client details
                builder: (context, clientSnapshot) {
                  if (!clientSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final clientData = clientSnapshot.data!;
                  final String clientName =
                      clientData['fullName'] ?? 'Unknown';
                  final Map<String, dynamic>? clientLocation =
                  request['location'];
                  final Timestamp? timestamp = request['timestamp'];
                  DateTime requestTime = timestamp != null
                      ? timestamp.toDate()
                      : DateTime.now();

                  double distance = 0.0;
                  final Map<String, dynamic> requestData =
                  request.data() as Map<String, dynamic>;

                  if (requestData.containsKey('location') &&
                      workerPosition != null) {
                    final clientLocation = requestData['location'];
                    if (clientLocation.containsKey('lat') &&
                        clientLocation.containsKey('lng')) {
                      distance = _calculateDistance(
                        workerPosition!.latitude,
                        workerPosition!.longitude,
                        clientLocation['lat'],
                        clientLocation['lng'],
                      );
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            "${AppLocalizations.of(context).translate('client')}: $clientName",
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${AppLocalizations.of(context).translate('description')}: ${request['description']}",
                              ),
                              Text(
                                "${AppLocalizations.of(context).translate('distance')}: ${distance.toStringAsFixed(2)} km",
                              ),
                              Text(
                                "${AppLocalizations.of(context).translate('request_time')}: ${_formatTimestamp(requestTime)}",
                              ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _showBidDialog(request.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade800,
                            ),
                            child: Text(
                              AppLocalizations.of(context).translate('bid'),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        // Display images attached to the request (if any)
                        if (requestData.containsKey('images') &&
                            (requestData['images'] as List).isNotEmpty)
                          Container(
                            height: 100,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                              (requestData['images'] as List).length,
                              itemBuilder: (context, imageIndex) {
                                final imageUrl =
                                (requestData['images'] as List)[imageIndex];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ImageGalleryPage(
                                          imageUrls: List<String>.from(
                                              requestData['images']),
                                          initialIndex: imageIndex,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 100,
                                    height: 100,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// ImageGalleryPage displays a list of images in a swipable PageView.
/// The initialIndex determines which image is shown first.
class ImageGalleryPage extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageGalleryPage(
      {Key? key, required this.imageUrls, required this.initialIndex})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    PageController controller = PageController(initialPage: initialIndex);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
        backgroundColor: Colors.red.shade800,
      ),
      body: PageView.builder(
        controller: controller,
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrls[index],
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}
