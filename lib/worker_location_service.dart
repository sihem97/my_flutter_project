import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerLocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Updates worker's location and FCM token in Firestore with latitude and longitude
  Future<void> updateWorkerLocation({
  required String workerId,
  required double latitude,
  required double longitude,
  required String fcmToken,
  required String service,
  }) async {
  try {
  // Store in workers_location collection (for GeoQueries)
  await _firestore.collection('workers_location').doc(workerId).set({
  'position': {
  'latitude': latitude,
  'longitude': longitude,
  'geopoint': GeoPoint(latitude, longitude), // Add GeoPoint for GeoFirestore
  },
  'fcmToken': fcmToken,
  'service': service,
  'lastUpdated': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  // Also update the users collection to maintain token consistency
  await _firestore.collection('users').doc(workerId).update({
  'fcmToken': fcmToken,
  'lastTokenUpdate': FieldValue.serverTimestamp(),
  });
  } catch (e) {
  print('Error updating worker location: $e');
  rethrow;
  }
  }

  // Fetch nearby workers within radius for a specific service
  Future<List<Map<String, dynamic>>> getNearbyWorkers({
    required double latitude,
    required double longitude,
    required double radius, // radius in kilometers
    required String service,
  }) async {
    // Convert radius to degrees (approximation)
    final double radiusInDegrees = radius / 111.0;

    // Query for nearby workers
    final List<Map<String, dynamic>> nearbyWorkers = [];

    // Get reference to workers_location collection
    final CollectionReference workersRef = _firestore.collection('workers_location');

    // Fetch all workers' locations
    final QuerySnapshot snapshot = await workersRef.get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final workerLatitude = data['position']['latitude'];
      final workerLongitude = data['position']['longitude'];

      // Calculate the distance using Haversine formula
      final double distance = _calculateDistance(latitude, longitude, workerLatitude, workerLongitude);

      if (distance <= radius && data['service'] == service && data['fcmToken'] != null) {
        nearbyWorkers.add({
          'workerId': doc.id,
          'fcmToken': data['fcmToken'],
          'distance': distance,
        });
      }
    }

    return nearbyWorkers;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Earth's radius in kilometers
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
            cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
                (sin(dLon / 2) * sin(dLon / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in kilometers
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}