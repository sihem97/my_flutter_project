import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'l10n/app_localizations.dart';

class TeacherListScreen extends StatefulWidget {
  final String subject;

  const TeacherListScreen({required this.subject, Key? key}) : super(key: key);

  @override
  _TeacherListScreenState createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LatLng? userPosition;
  List<Map<String, dynamic>> nearbyTeachers = [];
  bool isLoading = true;
  final double searchRadius = 100000; // 100km in meters - increased for testing

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location services are disabled")),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permissions are denied")),
            );
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          userPosition = LatLng(position.latitude, position.longitude);
        });
        print("User Location: ${position.latitude}, ${position.longitude}"); // Debug print
      }

      await _fetchNearbyTeachers();
    } catch (e) {
      print("Error getting location: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchNearbyTeachers() async {
    try {
      if (userPosition == null) {
        print("User position is null, cannot fetch nearby teachers.");
        setState(() {
          isLoading = false;
        });
        return;
      }


      QuerySnapshot teachersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .where('service', isEqualTo: 'tutoring')
          .where('subject', isEqualTo: widget.subject)
          .get();

      print("Found ${teachersSnapshot.docs.length} teachers matching initial criteria"); // Debug print

      List<Map<String, dynamic>> teachers = [];

      for (var doc in teachersSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        print("Processing teacher: ${data['name']}"); // Debug print

        // Handle nested location map
        double? lat;
        double? lng;

        if (data['location'] is Map) {
          var locationMap = data['location'] as Map;
          lat = locationMap['lat']?.toDouble();
          lng = locationMap['lng']?.toDouble();
        } else {
          // Try direct lat/lng fields
          lat = data['lat']?.toDouble();
          lng = data['lng']?.toDouble();
        }


        if (lat != null && lng != null) {
          double distance = _calculateDistance(
            userPosition!.latitude,
            userPosition!.longitude,
            lat,
            lng,
          );


          // Include teachers within searchRadius
          if (distance <= searchRadius) {
            teachers.add({
              'id': doc.id,
              'name': data['name'] ?? 'Unknown',
              'phone': data['phone'] ?? 'N/A',
              'email': data['email'] ?? 'N/A',
              'profileImageUrl': data['profileImageUrl'] ?? '',
              'distance': (distance / 1000).toStringAsFixed(2),
              'subscription': data['subscription'] ?? '',
              'educationLevel': data['educationLevel'] ?? '',
              'gender': data['gender'] ?? '',
              'phoneVerified': data['phoneVerified'] ?? false,
            });
            print("Added teacher ${data['name']} to results"); // Debug print
          } else {
            print("Teacher ${data['name']} is too far (${distance/1000} km)"); // Debug print
          }
        } else {
          print("Teacher ${data['name']} has invalid location data"); // Debug print
        }
      }

      // Sort teachers by distance
      teachers.sort((a, b) {
        return double.parse(a['distance']).compareTo(double.parse(b['distance']));
      });

      if (mounted) {
        setState(() {
          nearbyTeachers = teachers;
          isLoading = false;
        });
      }



    } catch (e) {
      print("Error fetching nearby teachers: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const int R = 6371000; // Earth radius in meters
    double phi1 = degreesToRadians(lat1);
    double phi2 = degreesToRadians(lat2);
    double deltaPhi = degreesToRadians(lat2 - lat1);
    double deltaLambda = degreesToRadians(lon2 - lon1);

    double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  double degreesToRadians(double deg) {
    return deg * (pi / 180);
  }

  void _showTeacherDetails(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(teacher['name']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("📧 ${AppLocalizations.of(context).translate('email')}: ${teacher['email']}", style: const TextStyle(fontSize: 16),),

              GestureDetector(
                onTap: () async {
                  final Uri phoneUri = Uri(scheme: 'tel', path: teacher['phone']);
                  if (await canLaunch(phoneUri.toString())) {
                    await launch(phoneUri.toString());
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Could not launch phone dialer")),
                    );
                  }
                },
                child: Text(
                  "📞 ${AppLocalizations.of(context).translate('phone')}: ${teacher['phone']}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue, // Make it look like a link
                  ),
                ),
              ),
              Text("📍 ${AppLocalizations.of(context).translate('distance')}: ${teacher['distance']} km", style: const TextStyle(fontSize: 16),),
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context).translate('contact_to_reserve')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('close')),
            ),
            ElevatedButton(
              onPressed: () => _reserveTeacher(teacher['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
              ),
              child: Text(AppLocalizations.of(context).translate('reserve')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reserveTeacher(String teacherId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('reservations').add({
        'teacherId': teacherId,
        'clientId': user.uid,
        'status': 'pending', // Initial status
        'timestamp': FieldValue.serverTimestamp(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('reservation_successful')),
        ),
      );
    } catch (e) {
      print("Error reserving teacher: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error reserving teacher")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          ' ${AppLocalizations.of(context).translate('nearby_teachers')}',
        ),
        backgroundColor: Colors.red.shade800,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : nearbyTeachers.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).translate('no_teachers_found'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : ListView.builder(
        itemCount: nearbyTeachers.length,
        itemBuilder: (context, index) {
          final teacher = nearbyTeachers[index];
          return Card(
            margin: const EdgeInsets.all(10),
            elevation: 4,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: Text(
                  teacher['name'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Row(
                children: [
                  Text(teacher['name']),
                  if (teacher['phoneVerified'])
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.verified,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("📍 ${teacher['distance']} km"),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => _showTeacherDetails(teacher),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  AppLocalizations.of(context).translate('contact'),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}