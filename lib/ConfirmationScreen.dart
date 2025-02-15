import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting date and time

class ConfirmationScreen extends StatelessWidget {
  final String idDemande;
  final String service;
  final String description;
  final List<String> imageUrls;
  final double latitude;
  final double longitude;
  final DateTime dateCreated;
  final double searchRadius; // Add this parameter

  const ConfirmationScreen({
    required this.idDemande,
    required this.service,
    required this.description,
    required this.imageUrls,
    required this.latitude,
    required this.longitude,
    required this.dateCreated,
    required this.searchRadius, // Include the selected radius
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirmation de la demande'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success message
            Text(
              'Votre demande a été envoyée avec succès!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // ID de la demande
            Text('ID de la demande:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(idDemande, style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),

            // Rayon de recherche (new addition)
            Text('Rayon de recherche:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('${searchRadius.round()} km', style: TextStyle(fontSize: 16)), // Display the selected radius
            SizedBox(height: 10),

            // Date de la demande
            Text('Date de la demande:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              DateFormat('yyyy-MM-dd').format(dateCreated), // Format date as YYYY-MM-DD
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),

            // Heure de la demande
            Text('Heure de la demande:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              DateFormat('HH:mm:ss').format(dateCreated), // Format time as HH:MM:SS
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),

            // Description du problème
            Text('Description du problème:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(description, style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),

            // Images (if any)
            if (imageUrls.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Images:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return Image.network(
                          imageUrls[index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}