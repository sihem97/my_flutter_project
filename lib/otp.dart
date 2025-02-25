import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_home.dart';
import 'worker_home.dart';
import 'l10n/app_localizations.dart';

class OtpScreen extends StatefulWidget {
  final String verificationID;
  final String userId;
  final bool isClient;

  const OtpScreen({
    super.key,
    required this.verificationID,
    required this.userId,
    required this.isClient,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController smsController = TextEditingController();

  void verifyOtp() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationID,
        smsCode: smsController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Update phone verification status in Firestore
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'phoneVerified': true,
      });

      // Navigate to the appropriate home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => widget.isClient ? ClientHomePage() : WorkerHomePage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('invalid_otp'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Full-screen gradient background
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade800, Colors.orange.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Added verification icon
                  Icon(Icons.verified_user, size: 48, color: Colors.green),
                  const SizedBox(height: 30),

                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: smsController,
                    keyboardType: TextInputType.number,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context).translate('verify_code'),
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
