import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'HistoryScreen.dart';
import 'accepted_reservation.dart';
import 'main.dart';
import 'sign_in.dart';
import 'worker_profile.dart';
import 'contact_us.dart';
import 'accepted_requests_screen.dart';
import 'pending_confirmations_screen.dart';
import 'l10n/app_localizations.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  _WorkerHomePageState createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  String workerName = "Worker"; // Default value, will be updated later
  String workerService = ""; // This stores the worker's service (e.g., "Plumbing")
  bool isTeacher = false; // Flag to check if worker is a teacher
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
    _fetchWorkerService(); // Fetch the worker's service
  }

  // Fetch the worker's name
  void _fetchWorkerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          workerName = doc.data()!['name'] ?? AppLocalizations.of(context).translate('worker');
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
          // Check if worker is a teacher
          isTeacher = workerService.toLowerCase() == "tutoring" ||
              workerService.toLowerCase() == "teacher" ||
              workerService.toLowerCase() == "teaching";
          print("Worker service fetched: $workerService, isTeacher: $isTeacher"); // Debug log
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
                title: AppLocalizations.of(context).translate('your_location')),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
    }
  }

  // Accept reservation for teachers
  Future<void> _acceptReservation(String reservationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update reservation status to accepted
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': 'accepted',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('reservation_accepted'))),
      );
    } catch (e) {
      print("Error accepting reservation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('error_accepting_reservation'))),
      );
    }
  }

  // Decline reservation for teachers
  Future<void> _declineReservation(String reservationId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Update reservation status to declined
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': 'declined',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('reservation_declined') ?? 'Reservation declined')),
      );
    } catch (e) {
      print("Error declining reservation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('error_declining_reservation') ?? 'Error declining reservation')),
      );
    }
  }

  // Show a dialog for the worker to submit a bid (for non-teachers)
  void _showBidDialog(String requestId) {
    TextEditingController priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context).translate('your_bid')),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                labelText: AppLocalizations.of(context).translate('enter_your_price')),
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

  // Submit a bid for a request (for non-teachers)
  Future<void> _submitBid(String requestId, double price) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      DocumentSnapshot requestDoc =
      await _firestore.collection('requests').doc(requestId).get();
      if (!requestDoc.exists) return;
      String? userId = requestDoc['userId'];
      if (userId == null) return;
      if (workerName == AppLocalizations.of(context).translate('worker')) {
        final workerDoc =
        await _firestore.collection('users').doc(user.uid).get();
        if (workerDoc.exists && workerDoc.data() != null) {
          workerName =
              workerDoc.data()!['name'] ?? AppLocalizations.of(context).translate('worker');
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
            content: Text(AppLocalizations.of(context).translate('bid_submitted_successfully'))),
      );
    } catch (e) {
      print("Error submitting bid: $e");
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const int R = 6371; // Earth's radius in km
    double dLat = (lat2 - lat1) * (pi / 180);
    double dLon = (lon2 - lon1) * (pi / 180);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180)) * cos(lat2 * (pi / 180)) *
            sin(dLon / 2) * sin(dLon / 2);

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
        title: Text(isTeacher
            ? AppLocalizations.of(context).translate('home') ?? 'Teacher Home'
            : AppLocalizations.of(context).translate('home')),
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
                  MaterialPageRoute(builder: (context) => const WorkerProfileScreen()),
                );
              },
            ),
            if (isTeacher) // Show different menu items for teachers
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(AppLocalizations.of(context).translate('accepted_reservations') ?? 'Accepted Reservations'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AcceptedReservationsScreen()),
                  );
                },
              )
            else ... [ // Menu items for regular workers
              ListTile(
                leading: const Icon(Icons.assignment_turned_in),
                title: Text(AppLocalizations.of(context).translate('accepted_requests')),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AcceptedRequestsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.hourglass_bottom),
                title: Text(AppLocalizations.of(context).translate('pending_confirmations')),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PendingConfirmationsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.history),
                title: Text(AppLocalizations.of(context).translate('history')),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: Text(AppLocalizations.of(context).translate('contact_us')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactUsScreen()),
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
                  MaterialPageRoute(builder: (context) => SignInScreen(MyApp.of(context).setLocale)),
                );
              },
            ),
          ],
        ),
      ),
      body: isTeacher
          ? _buildTeacherView() // Special view for teachers showing reservations
          : _buildServiceWorkerView(), // Regular view for other service workers
    );
  }

  // View for teachers showing reservations
  Widget _buildTeacherView() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reservations')
          .where('status', isEqualTo: 'pending')
          .where('teacherId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).translate('no_pending_reservations') ?? 'No pending reservations',
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final reservation = snapshot.data!.docs[index];
            final String clientId = reservation['clientId'];
            final Timestamp? timestamp = reservation['timestamp'];
            DateTime reservationTime = timestamp != null ? timestamp.toDate() : DateTime.now();

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(clientId).get(),
              builder: (context, clientSnapshot) {
                if (!clientSnapshot.hasData) {
                  return const Card(
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }

                final clientData = clientSnapshot.data!.data() as Map<String, dynamic>?;
                final String clientName = clientData?['fullName'] ?? clientData?['name'] ?? 'Unknown';

                return Card(
                  margin: const EdgeInsets.all(10),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${AppLocalizations.of(context).translate('student') ?? 'Student'}: $clientName",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "${AppLocalizations.of(context).translate('reservation_time') ?? 'Reservation Time'}: ${_formatTimestamp(reservationTime)}",
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => _declineReservation(reservation.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade800,
                                side: BorderSide(color: Colors.red.shade800),
                              ),
                              child: Text(
                                AppLocalizations.of(context).translate('decline') ?? 'Decline',
                              ),
                            ),
                            SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => _acceptReservation(reservation.id),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade800,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                AppLocalizations.of(context).translate('accept') ?? 'Accept',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Regular view for other service workers
  Widget _buildServiceWorkerView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('requests')
          .where('status', isEqualTo: 'pending')
          .where('service', isEqualTo: workerService)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context).translate('no_pending_requests'),
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final request = snapshot.data!.docs[index];
            final String userId = request['userId'];
            final Timestamp? timestamp = request['timestamp'];
            DateTime requestTime = timestamp != null ? timestamp.toDate() : DateTime.now();

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(userId).get(),
              builder: (context, clientSnapshot) {
                if (!clientSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clientData = clientSnapshot.data!;
                final String clientName = clientData['fullName'] ?? 'Unknown';

                double distance = 0.0;
                final Map<String, dynamic> requestData = request.data() as Map<String, dynamic>;

                if (requestData.containsKey('location') && workerPosition != null) {
                  final clientLocation = requestData['location'];
                  if (clientLocation.containsKey('lat') && clientLocation.containsKey('lng')) {
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
                  child: ListTile(
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
                );
              },
            );
          },
        );
      },
    );
  }
}