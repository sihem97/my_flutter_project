import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'dart:io'; // For file handling

class ServiceDetailsScreen extends StatefulWidget {
  final String service;

  ServiceDetailsScreen({required this.service});

  @override
  _ServiceDetailsScreenState createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  LatLng? clientPosition;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<File> _images = []; // To store selected images

  void _fetchClientLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      clientPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: MarkerId("client"),
          position: clientPosition!,
          infoWindow: InfoWindow(title: "Your Location"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(clientPosition!, 14),
    );

    _fetchNearbyWorkers();
  }

  void _fetchNearbyWorkers() async {
    QuerySnapshot workersSnapshot =
    await _firestore.collection('users').where('role', isEqualTo: 'worker').get();
    for (var doc in workersSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('location')) {
        double distance = _calculateDistance(
          clientPosition!.latitude,
          clientPosition!.longitude,
          data['location']['lat'],
          data['location']['lng'],
        );
        if (distance <= 10) {
          setState(() {
            _markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(data['location']['lat'], data['location']['lng']),
                infoWindow: InfoWindow(
                    title: data['name'], snippet: "Distance: ${distance.toStringAsFixed(2)} km"),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            );
          });
        }
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Radius of the Earth in km
    double dLat = (lat2 - lat1) * pi / 180;
    double dLon = (lon2 - lon1) * pi / 180;
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _images.add(File(pickedImage.path)); // Add the selected image to the list
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchClientLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.service} - Details'),
        backgroundColor: Colors.red[800], // Red theme
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[800]!, Colors.red[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: clientPosition ?? LatLng(0, 0),
                    zoom: 14,
                  ),
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    onPressed: () {
                      if (clientPosition != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(clientPosition!, 14),
                        );
                      }
                    },
                    child: Icon(Icons.my_location, color: Colors.white),
                    backgroundColor: Colors.red[800],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Describe your issue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Enter details about your issue...',
                        border: InputBorder.none, // Remove default border
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      maxLines: 3,
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Add Pictures',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Add Pictures', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_descriptionController.text.isNotEmpty) {
                            await _firestore.collection('requests').add({
                              'userId': FirebaseAuth.instance.currentUser!.uid,
                              'service': widget.service,
                              'description': _descriptionController.text,
                              'location': {'lat': clientPosition!.latitude, 'lng': clientPosition!.longitude},
                              'status': 'pending',
                              'images': [], // You can upload images to Firebase Storage and store URLs here
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Request Sent Successfully')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: Text('Send Request', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  ),
                  if (_images.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _images[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}