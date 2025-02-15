import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'sign_in.dart';
import 'worker_profile.dart';
import 'contact_us.dart';
import 'accepted_requests_screen.dart'; // Import the AcceptedRequestsScreen

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  _WorkerHomePageState createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  String workerName = "Worker";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LatLng? workerPosition;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchWorkerName();
    _fetchWorkerLocation();
  }

  void _fetchWorkerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          workerName = doc.data()!['name'] ?? "Worker";
        });
      }
    }
  }

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
          workerPosition = LatLng(doc.data()!['location']['lat'], doc.data()!['location']['lng']);
          _updateMap();
        });
      }
    }
  }

  void _updateMap() {
    if (workerPosition != null) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId("worker"),
            position: workerPosition!,
            infoWindow: const InfoWindow(title: "Your Location"),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      });
    }
  }

  // Method to show the bid dialog
  void _showBidDialog(String requestId) {
    TextEditingController priceController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Submit a Bid"),
          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Enter your price"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                double? price = double.tryParse(priceController.text);
                if (price != null && price > 0) {
                  await _submitBid(requestId, price);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a valid price")),
                  );
                }
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  // Method to submit a bid
  Future<void> _submitBid(String requestId, double price) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No authenticated user.");
      return;
    }
    try {
      DocumentSnapshot requestDoc = await _firestore.collection('requests').doc(requestId).get();
      if (!requestDoc.exists) {
        print("Request document not found.");
        return;
      }
      String? userId = requestDoc['userId'];
      if (userId == null) {
        print("Error: userId is missing in the request document.");
        return;
      }
      if (workerName == "Worker") {
        final workerDoc = await _firestore.collection('users').doc(user.uid).get();
        if (workerDoc.exists && workerDoc.data() != null) {
          workerName = workerDoc.data()!['name'] ?? "Worker";
        }
      }
      print("Submitting bid - Request ID: $requestId, User ID: $userId, Worker ID: ${user.uid}, Price: $price");
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
        const SnackBar(content: Text("Bid submitted successfully!")),
      );
      print("Bid submitted successfully.");
    } catch (e) {
      print("Error submitting bid: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Home'),
        backgroundColor: Colors.red.shade800,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Text("Menu", style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkerProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in),
              title: const Text('Accepted Requests'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AcceptedRequestsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: const Text('Contact Us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SignInScreen()));
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Listen for accepted bids
          StreamBuilder(
            stream: _firestore
                .collection('bids')
                .where('workerId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .where('status', isEqualTo: 'accepted')
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }

              // Get the latest accepted bid
              final acceptedBid = snapshot.data!.docs.first;
              print("Detected Accepted Bid: ${acceptedBid.data()}");

              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (context.mounted) {
                  try {
                    // Fetch the related request document
                    final requestDoc = await _firestore
                        .collection('requests')
                        .doc(acceptedBid['requestId'])
                        .get();

                    // Debug: Print the request details
                    print("Related Request Details: ${requestDoc.data()}");

                    // Show dialog only if the request exists and context is mounted
                    if (context.mounted && requestDoc.exists) {
                      String service = requestDoc.data()?['service'] ?? 'Unknown Service';
                      String description = requestDoc.data()?['description'] ?? 'No Description';

                      // Prevent duplicate notifications by marking the bid as "notified"
                      await _firestore.collection('bids').doc(acceptedBid.id).update({
                        'notified': true, // Add a new field to track notification status
                      });

                      showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Bid Accepted!'),
                            content: Text(
                              'Your bid for $service has been accepted!\nDescription: $description',
                            ),
                            actions: [
                              TextButton(
                                child: const Text('OK'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    }
                  } catch (e) {
                    print("Error processing accepted bid: $e");
                  }
                }
              });

              return const SizedBox.shrink();
            },
          ),

          // Pending requests list
          Expanded(
            child: StreamBuilder(
              stream: _firestore.collection('requests').where('status', isEqualTo: 'pending').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    return ListTile(
                      title: Text("Service: ${doc['service']}"),
                      subtitle: Text("Description: ${doc['description']}"),
                      trailing: ElevatedButton(
                        onPressed: () => _showBidDialog(doc.id),
                        child: const Text("Bid"),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}