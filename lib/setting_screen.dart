import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile Settings',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.edit),
              onTap: () {
                // Handle edit profile
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Change Password'),
              trailing: const Icon(Icons.lock),
              onTap: () {
                // Handle password change
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Logout'),
              trailing: const Icon(Icons.exit_to_app),
              onTap: () {
                // Handle logout
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
