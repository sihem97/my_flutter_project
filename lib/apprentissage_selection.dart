import 'package:flutter/material.dart';

class ApprentissageSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apprentissage Services'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a Course for Apprentissage',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Course 1: Introduction to Plumbing'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Navigate to course details
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Course 2: Gardening Basics'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Navigate to course details
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Course 3: Electrical Engineering'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                // Navigate to course details
              },
            ),
            // Add more courses as necessary
          ],
        ),
      ),
    );
  }
}
