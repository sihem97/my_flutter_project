import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'phone_ver.dart';
import 'package:flutter/gestures.dart';
import 'terms_and_conditions.dart';
import 'l10n/app_localizations.dart'; // ✅ Import localization

class ClientSignUpScreen extends StatefulWidget {
  const ClientSignUpScreen({super.key});

  @override
  State<ClientSignUpScreen> createState() => _ClientSignUpScreenState();
}

class _ClientSignUpScreenState extends State<ClientSignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  final formKey = GlobalKey<FormState>();
  bool acceptedTerms = false; // Tracks if the user accepted Terms & Conditions

  @override
  void initState() {
    super.initState();
    // Prefill phone field with +213
    phoneController.text = '+213 ';
  }

  Future<void> signUp() async {
    if (!formKey.currentState!.validate()) return;

    // Check if Terms and Conditions are accepted
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('accept_terms'))),
      );
      return;
    }

    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('password_mismatch'))),
      );
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim());

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
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
            userId: userCredential.user!.uid,
            isClient: true,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? AppLocalizations.of(context).translate('error_occurred'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: fullNameController,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('full_name')),
                  prefixIcon: const Icon(Icons.person, color: Colors.red),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('email')),
                  prefixIcon: const Icon(Icons.email, color: Colors.red),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('phone_number')),
                  prefixIcon: const Icon(Icons.phone, color: Colors.red),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('address')),
                  prefixIcon: const Icon(Icons.home, color: Colors.red),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('password')),
                  prefixIcon: const Icon(Icons.lock, color: Colors.red),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('confirm_password')),
                  prefixIcon: const Icon(Icons.lock, color: Colors.red),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 30),
              // Terms and Conditions Checkbox and Link
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: acceptedTerms,
                    activeColor: Colors.red.shade800,
                    onChanged: (value) {
                      setState(() {
                        acceptedTerms = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: AppLocalizations.of(context).translate('accept_terms'),
                        style: const TextStyle(color: Colors.black),
                        children: [
                          TextSpan(
                            text: AppLocalizations.of(context).translate('terms_conditions'),
                            style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TermsAndConditionsScreen(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: size.width,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      signUp();
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context).translate('signup'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
