import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'l10n/app_localizations.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({super.key});

  @override
  _WorkerProfileScreenState createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _profileImageUrl;

  Future<void> _uploadProfilePicture() async {
    try {
      // Pick an image from the gallery
      final pickedImage =
      await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage == null) return;

      // Get the current user
      final user = _auth.currentUser;
      if (user == null) return;

      // Upload the image to Firebase Storage
      final storageRef = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}.jpg');

      await storageRef.putFile(File(pickedImage.path));

      // Get the download URL of the uploaded image
      final downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore with the new profile image URL
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageUrl': downloadUrl,
      });

      // Update the local state to refresh the UI
      setState(() {
        _profileImageUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context).translate('profile_pic_updated')),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "${AppLocalizations.of(context).translate('error_updating_profile_pic')}: $e"),
        ),
      );
    }
  }

  void _changePassword(BuildContext context) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _auth.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)
                .translate('password_reset_sent')),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "${AppLocalizations.of(context).translate('error')}: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to calculate age based on the birthday string (format: d/M/yyyy)
  String _calculateAgeString(String? birthday) {
    if (birthday == null || birthday.isEmpty) {
      return AppLocalizations.of(context).translate('no_age');
    }
    try {
      final parts = birthday.split('/');
      if (parts.length != 3) {
        return AppLocalizations.of(context).translate('no_age');
      }
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final birthdayDate = DateTime(year, month, day);
      final today = DateTime.now();
      int age = today.year - birthdayDate.year;
      if (today.month < birthdayDate.month ||
          (today.month == birthdayDate.month && today.day < birthdayDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return AppLocalizations.of(context).translate('no_age');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('profile')),
        backgroundColor: Colors.red.shade800,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
                child: Text(AppLocalizations.of(context)
                    .translate('no_profile_data')));
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final bool isApprentissage = userData['service'] == 'apprentissage';

          // Calculate age from birthday
          final String ageString = _calculateAgeString(userData['birthday']);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage:
                      (_profileImageUrl ?? userData['profileImageUrl']) != null &&
                          (_profileImageUrl ?? userData['profileImageUrl'])
                              .isNotEmpty
                          ? NetworkImage(_profileImageUrl ?? userData['profileImageUrl'])
                          : null,
                      child: (_profileImageUrl ?? userData['profileImageUrl']) == null ||
                          (_profileImageUrl ?? userData['profileImageUrl'])
                              .isEmpty
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Worker Name
                Text(
                  userData['name'] ??
                      AppLocalizations.of(context).translate('no_name'),
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 10),
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
                            userData['email'] ??
                                AppLocalizations.of(context).translate('no_email')),
                        _buildDetailRow(
                            Icons.phone,
                            AppLocalizations.of(context).translate('phone'),
                            userData['phone'] ??
                                AppLocalizations.of(context).translate('no_phone')),
                        _buildDetailRow(
                            Icons.cake,
                            AppLocalizations.of(context).translate('age'),
                            ageString),
                        _buildDetailRow(
                            Icons.wc,
                            AppLocalizations.of(context).translate('gender'),
                            AppLocalizations.of(context)
                                .translate(userData['gender'] ?? 'no_gender')),
                        _buildDetailRow(
                            Icons.work,
                            AppLocalizations.of(context).translate('service'),
                            AppLocalizations.of(context)
                                .translate(userData['service'] ?? 'no_service')),
                        if (isApprentissage) ...[
                          _buildDetailRow(
                              Icons.school,
                              AppLocalizations.of(context).translate('education'),
                              userData['educationLevel'] ??
                                  AppLocalizations.of(context).translate('no_education')),
                          _buildDetailRow(
                              Icons.book,
                              AppLocalizations.of(context).translate('subject'),
                              userData['subject'] ??
                                  AppLocalizations.of(context).translate('no_subject')),
                        ],
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
                // Button to upload/change the profile picture
                ElevatedButton.icon(
                  onPressed: _uploadProfilePicture,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(AppLocalizations.of(context)
                      .translate('change_profile_picture')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Reviews Section with aggregation and detailed view support.
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.red.shade800, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "$label: $value",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('edit_profile')),
        backgroundColor: Colors.red.shade800,
      ),
      body: Center(
        child: Text(AppLocalizations.of(context).translate('edit_profile_screen')),
      ),
    );
  }
}
