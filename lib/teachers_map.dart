import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _fetchUserLocation();
  }

  void _fetchUserLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      userPosition = LatLng(position.latitude, position.longitude);
    });

    _fetchNearbyTeachers();
  }

  void _fetchNearbyTeachers() async {
    QuerySnapshot teachersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .where('subject', isEqualTo: widget.subject)
        .get();

    List<Map<String, dynamic>> teachers = [];

    for (var doc in teachersSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('location') && userPosition != null) {
        double distance = _calculateDistance(
          userPosition!.latitude,
          userPosition!.longitude,
          data['location']['lat'],
          data['location']['lng'],
        );

        teachers.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'profilePic': data['profilePic'] ?? '',
          'email': data['email'] ?? '',
          'phone': data['phone'] ?? '',
          'distance': (distance / 1000).toStringAsFixed(2),
        });
      }
    }

    setState(() {
      nearbyTeachers = teachers;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const int R = 6371000;
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
            children: [
              Text("📧 Email: ${teacher['email']}"),
              Text("📞 Phone: ${teacher['phone']}"),
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context)
                  .translate('contact_to_reserve')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('close')),
            ),
            ElevatedButton(
              onPressed: () => _reserveTeacher(teacher['id']),
              child: Text(AppLocalizations.of(context).translate('reserve')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reserveTeacher(String teacherId) async {
    String userId = "CURRENT_USER_ID"; // Replace with actual user ID from FirebaseAuth

    await _firestore.collection('reservations').add({
      'teacherId': teacherId,
      'parentId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).translate('reservation_successful'))),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppLocalizations.of(context).translate(widget.subject)} - ${AppLocalizations.of(context).translate('nearby_teachers')}',
        ),
        backgroundColor: Colors.red.shade800,
      ),
      body: nearbyTeachers.isEmpty
          ? Center(
        child: Text(
          AppLocalizations.of(context).translate('no_teachers_found'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
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
                backgroundImage: teacher['profilePic'].isNotEmpty
                    ? NetworkImage(teacher['profilePic'])
                    : null,
                child: teacher['profilePic'].isEmpty
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(teacher['name']),
              subtitle: Text(
                  "${teacher['distance']} km away"),
              trailing: ElevatedButton(
                onPressed: () => _showTeacherDetails(teacher),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                ),
                child: Text(AppLocalizations.of(context).translate('contact')),
              ),
            ),
          );
        },
      ),
    );
  }
}
