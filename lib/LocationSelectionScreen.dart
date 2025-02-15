import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'ConfirmationScreen.dart';
import 'package:intl/intl.dart'; // For formatting date and time
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math'; // For random number generation

// Function to generate a short alphanumeric ID
String generateShortId(int length) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  Random rnd = Random();
  return String.fromCharCodes(Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
}

// Fetch nearby workers based on radius and service type
Future<List<String>> fetchNearbyWorkers({
  required Position clientPosition,
  required double maxDistance, // Radius in km
  required String serviceType, // Selected service type
}) async {
  try {
    final List<String> workerTokens = [];

    // Fetch all workers from Firestore
    final QuerySnapshot workerSnapshots = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'worker') // Filter for workers
        .where('service', arrayContains: serviceType) // Match worker's services
        .get();

    // Calculate distance for each worker and filter by proximity
    for (var doc in workerSnapshots.docs) {
      final workerData = doc.data() as Map<String, dynamic>;
      final workerLatitude = workerData['latitude'] as double?;
      final workerLongitude = workerData['longitude'] as double?;

      if (workerLatitude != null && workerLongitude != null) {
        final distance = Geolocator.distanceBetween(
          clientPosition.latitude,
          clientPosition.longitude,
          workerLatitude,
          workerLongitude,
        );

        // If the worker is within the specified radius, add their FCM token
        if (distance <= maxDistance * 1000) { // Convert km to meters
          final fcmToken = workerData['fcmToken'] as String?;
          if (fcmToken != null) {
            workerTokens.add(fcmToken);
          }
        }
      }
    }

    return workerTokens;
  } catch (e) {
    print('Error fetching nearby workers: $e');
    return [];
  }
}

// Send notifications to workers
Future<void> _sendNotificationToWorkers({
  required String titre,
  required String texte,
  required String idDemande,
  required List<String> workerTokens,
}) async {
  try {
    final notificationData = jsonEncode({
      'notification': {'title': titre, 'body': texte},
      'data': {'idDemande': idDemande}, // Pass the ID of the request
    });

    for (var token in workerTokens) {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=YOUR_FCM_SERVER_KEY', // Replace with your FCM Server Key
        },
        body: jsonEncode({
          ...jsonDecode(notificationData), // Include notification data
          'to': token, // Worker's FCM token
        }),
      );
    }

    print('Notifications sent successfully to ${workerTokens.length} workers.');
  } catch (e) {
    print('Error sending notifications: $e');
  }
}

class LocationSelectionScreen extends StatefulWidget {
  final String service;
  final String description;
  final List<String> imageUrls;

  const LocationSelectionScreen({
    required this.service,
    required this.description,
    required this.imageUrls,
  });

  @override
  _LocationSelectionScreenState createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  double _selectedRadius = 5; // Default radius in km
  List<double> radiusOptions = [5, 10, 20]; // Available radius options

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez activer les services de localisation.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Autorisation de localisation refusée.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Les autorisations de localisation sont refusées pour toujours.')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _addMarkers(position);
      });

      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15, // Reasonable zoom level
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'obtention de la position: $e')),
      );
    }
  }

  void _addMarkers(Position position) {
    _markers.clear();

    // Add a marker for the user's location
    _markers.add(
      Marker(
        markerId: MarkerId('user_location'),
        position: LatLng(position.latitude, position.longitude),
        infoWindow: InfoWindow(title: 'Votre position'),
      ),
    );

    // Fetch real workers from Firestore
    _fetchAndDisplayWorkers(position);
  }

  Future<void> _fetchAndDisplayWorkers(Position position) async {
    try {
      print('Fetching workers for service: ${widget.service.toLowerCase()}');
      print('Selected radius: $_selectedRadius km');

      // Fetch workers matching the selected service and within the radius
      final QuerySnapshot workerSnapshots = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .where('services', arrayContains: widget.service.toLowerCase())
          .get();

      print('Found ${workerSnapshots.docs.length} total workers');

      int workersInRange = 0;
      _markers.clear(); // Clear existing markers except user location

      // Add back the user location marker
      _markers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(title: 'Votre position'),
        ),
      );

      for (var doc in workerSnapshots.docs) {
        final workerData = doc.data() as Map<String, dynamic>;
        print('Worker data: $workerData'); // Debug worker data

        final workerLatitude = workerData['latitude'] as double?;
        final workerLongitude = workerData['longitude'] as double?;

        if (workerLatitude != null && workerLongitude != null) {
          final distance = Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            workerLatitude,
            workerLongitude,
          );

          print('Worker distance: ${distance / 1000} km');

          if (distance <= _selectedRadius * 1000) {
            workersInRange++;
            BitmapDescriptor workerIcon = BitmapDescriptor.defaultMarker;

            String workerInfo = '${workerData['name'] ?? 'Unknown'} (${workerData['role'] ?? 'Unknown role'})';
            if (workerData['available'] == true) {
              workerInfo += ' - Disponible';
            } else {
              workerInfo += ' - Indisponible';
            }
            workerInfo += ' - ${(distance / 1000).toStringAsFixed(2)} km';

            _markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(workerLatitude, workerLongitude),
                icon: workerIcon,
                infoWindow: InfoWindow(
                  title: workerInfo,
                  snippet: 'Téléphone: ${workerData['phone'] ?? 'No phone'}',
                ),
              ),
            );
          }
        } else {
          print('Worker missing location data: ${doc.id}');
        }
      }

      print('Added $workersInRange workers within ${_selectedRadius}km radius');
      setState(() {}); // Update markers on the map
    } catch (e) {
      print('Error fetching workers: $e');
    }
  }

  Future<void> _sendDataToWorkers() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veuillez partager votre emplacement.')),
      );
      return;
    }

    try {
      final String idDemande = generateShortId(6); // Generate a 6-character ID
      final DateTime dateCreated = DateTime.now(); // Current date and time

      // Save the request data to Firestore, including the selected radius
      await FirebaseFirestore.instance.collection('requests').doc(idDemande).set({
        'idDemande': idDemande,
        'service': widget.service,
        'description': widget.description,
        'imageUrls': widget.imageUrls,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'dateCreated': dateCreated.toIso8601String(),
        'devis': 'Not defined yet',
        'state': 'New',
        'searchRadius': _selectedRadius, // Save the selected radius
      });

      // Fetch nearby workers based on the selected radius and service type
      final List<String> nearbyWorkerTokens = await fetchNearbyWorkers(
        clientPosition: _currentPosition!,
        maxDistance: _selectedRadius, // Use the selected radius
        serviceType: widget.service.toLowerCase(), // Match worker's services
      );

      // Send notifications to nearby workers
      if (nearbyWorkerTokens.isNotEmpty) {
        await _sendNotificationToWorkers(
          titre: "Nouvelle demande",
          texte: "Un client recherche un professionnel dans votre zone.",
          idDemande: idDemande,
          workerTokens: nearbyWorkerTokens,
        );
      } else {
        print('No nearby workers found.');
      }

      // Navigate to the ConfirmationScreen with all details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationScreen(
            idDemande: idDemande,
            service: widget.service,
            description: widget.description,
            imageUrls: widget.imageUrls,
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            dateCreated: dateCreated,
            searchRadius: _selectedRadius, // Pass the selected radius
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partager votre emplacement'),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                _mapController.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    15,
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition?.latitude ?? 0,
                _currentPosition?.longitude ?? 0,
              ),
              zoom: 15,
            ),
            markers: _markers,
          ),
          Positioned(
            bottom: 120, // Adjusted position for the radius selector
            left: 20,
            right: 20,
            child: DropdownButtonFormField<double>(
              value: _selectedRadius,
              items: radiusOptions.map((double radius) {
                return DropdownMenuItem(
                  value: radius,
                  child: Text('$radius km'), // Display radius in km
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRadius = value!; // Update the selected radius
                  if (_currentPosition != null) {
                    _fetchAndDisplayWorkers(_currentPosition!); // Refresh markers based on new radius
                  }
                });
              },
              decoration: InputDecoration(
                labelText: 'Rayon de recherche',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _sendDataToWorkers,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Envoyer ma demande',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}