import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  void _changePassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset email sent. Check your inbox."),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No profile data found.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final bool isApprentissage = userData['service'] == 'apprentissage';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 60,
                  backgroundImage: userData['profileImage'] != null &&
                      userData['profileImage'].isNotEmpty
                      ? NetworkImage(userData['profileImage'])
                      : null,
                  child: userData['profileImage'] == null ||
                      userData['profileImage'].isEmpty
                      ? const Icon(Icons.person, size: 60)
                      : null,
                ),
                const SizedBox(height: 20),

                // Worker Name
                Text(
                  userData['name'] ?? 'No Name',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Email
                ListTile(
                  leading: const Icon(Icons.email, color: Colors.red),
                  title: Text(userData['email'] ?? 'No Email', style: const TextStyle(fontSize: 16)),
                ),

                // Phone Number
                ListTile(
                  leading: const Icon(Icons.phone, color: Colors.red),
                  title: Text(userData['phone'] ?? 'No Phone', style: const TextStyle(fontSize: 16)),
                ),

                // Age
                ListTile(
                  leading: const Icon(Icons.cake, color: Colors.red),
                  title: Text('Age: ${userData['age'] ?? 'No Age'}', style: const TextStyle(fontSize: 16)),
                ),

                // Gender
                ListTile(
                  leading: const Icon(Icons.wc, color: Colors.red),
                  title: Text('Gender: ${userData['gender'] ?? 'No Gender'}', style: const TextStyle(fontSize: 16)),
                ),

                // Service Provided
                ListTile(
                  leading: const Icon(Icons.work, color: Colors.red),
                  title: Text('Service: ${userData['service'] ?? 'No Service'}', style: const TextStyle(fontSize: 16)),
                ),

                // Show Education Level & Subject only if service is "apprentissage"
                if (isApprentissage) ...[
                  if (userData['educationLevel'] != null)
                    ListTile(
                      leading: const Icon(Icons.school, color: Colors.red),
                      title: Text('Education: ${userData['educationLevel']}', style: const TextStyle(fontSize: 16)),
                    ),
                  if (userData['subject'] != null)
                    ListTile(
                      leading: const Icon(Icons.book, color: Colors.red),
                      title: Text('Subject: ${userData['subject']}', style: const TextStyle(fontSize: 16)),
                    ),
                ],

                const SizedBox(height: 20),

                // Change Password Button
                ElevatedButton.icon(
                  onPressed: () => _changePassword(context),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text("Change Password"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
