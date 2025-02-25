import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'l10n/app_localizations.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  _ClientProfileScreenState createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _changePassword(BuildContext context) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _auth.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('password_reset_sent')),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${AppLocalizations.of(context).translate('error')}: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('profile')),
        backgroundColor: Colors.red.shade800, // Different color for client profile
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
                child: Text(AppLocalizations.of(context).translate('no_profile_data')));
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Full Name
                Text(
                  userData['fullName'] ?? AppLocalizations.of(context).translate('no_name'),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 30),

                // Details Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildDetailRow(
                            Icons.email,
                            AppLocalizations.of(context).translate('email'),
                            userData['email'] ?? AppLocalizations.of(context).translate('no_data')),
                        _buildDetailRow(
                            Icons.phone,
                            AppLocalizations.of(context).translate('phone'),
                            userData['phone'] ?? AppLocalizations.of(context).translate('no_data'),
                            forceLTR: true), // Fixes phone number formatting
                        _buildDetailRow(
                            Icons.location_on,
                            AppLocalizations.of(context).translate('address'),
                            userData['address'] ?? AppLocalizations.of(context).translate('no_data')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Change Password Button
                ElevatedButton.icon(
                  onPressed: () => _changePassword(context),
                  icon: const Icon(Icons.lock_reset),
                  label: Text(AppLocalizations.of(context).translate('change_password')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool forceLTR = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.red.shade800, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 19, color: Colors.black),
                children: [
                  TextSpan(text: "$label: "),
                  if (forceLTR)
                    WidgetSpan(
                      child: Directionality(
                        textDirection: TextDirection.ltr, // Forces LTR for the number only
                        child: Text("\u200E$value", style: const TextStyle(fontSize: 16)),
                      ),
                    )
                  else
                    TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
