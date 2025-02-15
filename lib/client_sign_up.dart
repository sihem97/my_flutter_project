import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'phone_ver.dart';

class ClientSignUpScreen extends StatefulWidget {
  const ClientSignUpScreen({super.key});

  @override
  State<ClientSignUpScreen> createState() => _ClientSignUpScreenState();
}

class _ClientSignUpScreenState extends State<ClientSignUpScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  Future<void> signUp() async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'role': 'client',
        'email': emailController.text.trim(),
        'fullName': fullNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'address': addressController.text.trim(),
        'phoneVerified': false,
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhoneVerificationScreen(
            phoneNumber: phoneController.text.trim(),
            userId: userCredential.user!.uid, // Pass userId
            isClient: true, // Indicate client
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'An error occurred')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
              TextFormField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: 'Password')),
              TextFormField(controller: confirmPasswordController, obscureText: true, decoration: InputDecoration(labelText: 'Confirm Password')),
              TextFormField(controller: fullNameController, decoration: InputDecoration(labelText: 'Full Name')),
              TextFormField(controller: phoneController, decoration: InputDecoration(labelText: 'Phone Number')),
              TextFormField(controller: addressController, decoration: InputDecoration(labelText: 'Address')),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) signUp();
                },
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
