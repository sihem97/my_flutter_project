// Role Selection Page (role_selection.dart)
import 'package:flutter/material.dart';
import 'client_sign_up.dart';
import 'worker_sign_up.dart';

class RoleSelectionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WorkerSignUpScreen()),
              ),
              child: const Text('Sign Up as Worker'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClientSignUpScreen()),
              ),
              child: const Text('Sign Up as Client'),
            ),
          ],
        ),
      ),
    );
  }
}