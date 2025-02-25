import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'worker_home.dart';
import 'client_home.dart';
import 'sign_in.dart';
import 'main.dart'; // ✅ Import MyApp to access setLocale

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is logged in, check their role
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnapshot.hasData) {
                String role = roleSnapshot.data!['role'];

                // Navigate to the correct screen based on the user's role
                if (role == 'worker') {
                  return const WorkerHomePage();  // Navigate to Worker Home
                } else if (role == 'client') {
                  return ClientHomePage();  // Navigate to Client Home
                }
              }

              // ❌ OLD (Incorrect)
              // return const SignInScreen();

              // ✅ FIXED: Pass the locale function
              return SignInScreen(MyApp.of(context).setLocale);
            },
          );
        }

        // ❌ OLD (Incorrect)
        // return const SignInScreen();

        // ✅ FIXED: Pass the locale function
        return SignInScreen(MyApp.of(context).setLocale);
      },
    );
  }
}
