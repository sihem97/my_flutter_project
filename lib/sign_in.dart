import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_home.dart';
import 'worker_home.dart';
import 'role_selection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

class SignInScreen extends StatefulWidget {
  final Function(Locale) setLocale; // Function to change language
  const SignInScreen(this.setLocale, {super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  Future<void> _loginUser(BuildContext context) async {
    try {
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Récupérer le rôle de l'utilisateur depuis Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        if (userDoc.exists) {
          String role = userDoc['role']; // Obtenir le rôle de l'utilisateur

          // Navigation en fonction du rôle
          if (role == 'client') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ClientHomePage()),
            );
          } else if (role == 'worker') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WorkerHomePage()),

            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rôle non reconnu')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur non trouvé')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[800],
        actions: [
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language, color: Colors.white), // 🌍 Language Icon
            onSelected: (Locale locale) async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('language', locale.languageCode);
              widget.setLocale(locale);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
              PopupMenuItem(value: const Locale('fr'), child: const Text('Français')),
              PopupMenuItem(value: const Locale('en'), child: const Text('English')),
              PopupMenuItem(value: const Locale('ar'), child: const Text('العربية')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context).translate('email_required');
                  }
                  if (!value.contains('@')) {
                    return AppLocalizations.of(context).translate('invalid_email');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('email')),
                  prefixIcon: const Icon(Icons.email, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppLocalizations.of(context).translate('password_required');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  label: Text(AppLocalizations.of(context).translate('password')),
                  prefixIcon: const Icon(Icons.lock, color: Colors.red),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red.shade800)),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: size.width,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _loginUser(context);
                    }
                  },
                  child: Text(
                    AppLocalizations.of(context).translate('sign_in'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center (
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoleSelectionScreen(),
                      ),
                    );
                  },
                  child: Text(
                    AppLocalizations.of(context).translate('no_account'),
                    style: const TextStyle(fontSize: 16, color: Colors.red),
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
