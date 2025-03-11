import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'dart:io'; // For file handling
import 'l10n/app_localizations.dart';
import 'my_requests.dart'; // Import localization

class ServiceDetailsScreen extends StatefulWidget {
  // IMPORTANT: Ensure that the 'service' passed here is the raw key,
  // not the translated value. For example, pass "Plumbing" rather than
  // AppLocalizations.of(context).translate('services.Plumbing').
  final String service;

  const ServiceDetailsScreen({required this.service});

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
  double _selectedRadius = 5; // Default radius in kilometers

  void _fetchClientLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('location_services_disabled'))),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .translate('location_permissions_denied'))),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('location_permissions_denied_forever'))),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      clientPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId("client"),
          position: clientPosition!,
          infoWindow: InfoWindow(
              title: AppLocalizations.of(context).translate('your_location')),
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
    // Fetch workers who match the requested service and are within the selected radius
    QuerySnapshot workersSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'worker')
        .where('service', isEqualTo: widget.service) // This compares to the raw key!
        .get();

    Set<Marker> markers = {};
    if (clientPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId("client"),
          position: clientPosition!,
          infoWindow: InfoWindow(
              title: AppLocalizations.of(context).translate('your_location')),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    for (var doc in workersSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('location')) {
        double distance = _calculateDistance(
          clientPosition!.latitude,
          clientPosition!.longitude,
          data['location']['lat'],
          data['location']['lng'],
        );

        if (distance <= _selectedRadius * 1000) { // Convert km to meters
          markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: LatLng(data['location']['lat'], data['location']['lng']),
              infoWindow: InfoWindow(
                title:
                "${data['name'] ?? AppLocalizations.of(context).translate('worker')}",
                snippet:
                "${(distance / 1000).toStringAsFixed(2)} ${AppLocalizations.of(context).translate('km_away')}",
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        }
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const int R = 6371000; // Earth's radius in meters
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
        title: Text('${widget.service} - ${AppLocalizations.of(context).translate('details')}'),
        backgroundColor: Colors.red[800],
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).translate('select_radius'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              DropdownButton<double>(
                value: _selectedRadius,
                items: [1.0, 5.0, 10.0].map<DropdownMenuItem<double>>((value) {
                  return DropdownMenuItem<double>(
                    value: value,
                    child: Text('$value ${AppLocalizations.of(context).translate('km')}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRadius = value!;
                    _fetchNearbyWorkers(); // Refresh workers when radius changes
                  });
                },
              ),
            ],
          ),
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: clientPosition ?? const LatLng(0, 0),
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
                    child: const Icon(Icons.my_location, color: Colors.white),
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
                    AppLocalizations.of(context).translate('describe_your_issue'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    ),
                    child: TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).translate('enter_details_about_your_issue'),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      maxLines: 3,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context).translate('add_pictures'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
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
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(AppLocalizations.of(context).translate('add_pictures'), style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_descriptionController.text.isNotEmpty && clientPosition != null) {
                            await _firestore.collection('requests').add({
                              'userId': FirebaseAuth.instance.currentUser!.uid,
                              // CHANGE: Use widget.service as the raw key.
                              // Ensure that when calling ServiceDetailsScreen, you pass a raw value (e.g., "Plumbing")
                              'service': widget.service,
                              'description': _descriptionController.text,
                              'location': {
                                'lat': clientPosition!.latitude,
                                'lng': clientPosition!.longitude,
                              },
                              'status': 'pending',
                              'timestamp': FieldValue.serverTimestamp(),
                              'images': [], // You can upload images to Firebase Storage and store URLs here
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context).translate('request_sent_successfully'))),
                            );
                            // ** Redirect the user to "My Requests" after successful submission **
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const MyRequestsScreen()),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppLocalizations.of(context).translate('fill_all_fields_and_enable_location'))),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                        ),
                        child: Text(AppLocalizations.of(context).translate('send_request'), style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ],
                  ),
                  if (_images.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
