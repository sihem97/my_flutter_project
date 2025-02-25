import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conditions Générales"),
        backgroundColor: Colors.red.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: const Text(
          '''Insérez ici le texte complet de vos conditions générales.
          
          Par exemple, vous pouvez détailler les droits et responsabilités des utilisateurs, 
          les conditions d'utilisation, la politique de confidentialité, etc.

          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
          ''',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
