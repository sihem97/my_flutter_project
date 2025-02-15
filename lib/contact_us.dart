import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  final String email = "support@company.com";
  final String phoneNumber = "+1234567890";

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {'subject': 'Support Inquiry'},
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      debugPrint("Could not launch email");
    }
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint("Could not launch phone");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contact Us"), backgroundColor: Colors.red),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Get in Touch",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "If you have any questions or need support, feel free to contact us via email or phone.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Email Section
            ListTile(
              leading: const Icon(Icons.email, color: Colors.red),
              title: Text(
                email,
                style: const TextStyle(fontSize: 18, color: Colors.blue, decoration: TextDecoration.underline),
              ),
              onTap: _launchEmail,
            ),

            // Phone Section
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.red),
              title: Text(
                phoneNumber,
                style: const TextStyle(fontSize: 18, color: Colors.blue, decoration: TextDecoration.underline),
              ),
              onTap: _launchPhone,
            ),
          ],
        ),
      ),
    );
  }
}
