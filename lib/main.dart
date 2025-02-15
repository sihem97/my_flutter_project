import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sign_in.dart'; // Assuming you already have this for the sign-in screen
import 'client_home.dart'; // Add the ClientHomePage import here
import 'worker_home.dart'; // Add the WorkerHomePage import here
import 'package:pin_code_fields/pin_code_fields.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthCheck(), // This widget will handle the user role check
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          // Retrieve the role from Firestore
          setState(() {
            _userRole = userDoc['role'] ?? 'client'; // Default to 'client' if role is not found
            _isLoading = false;
          });
        }
      } catch (e) {
        // Handle any errors
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // No user is logged in, so move to sign-in screen
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading indicator while we check the user role
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userRole == null) {
      // User is not logged in, redirect to sign-in screen
      return const SignInScreen();
    }

    // Based on the role, navigate to the corresponding screen
    if (_userRole == 'worker') {
      return const WorkerHomePage(); // Navigate to worker's home page
    } else {
      return  ClientHomePage(); // Navigate to client's home page
    }
  }
}
