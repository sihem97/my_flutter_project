import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_home.dart';
import 'worker_home.dart';

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
  TextEditingController smsController = TextEditingController();

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

      // Navigate to correct home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => widget.isClient ? ClientHomePage() : WorkerHomePage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PinCodeTextField(
              appContext: context,
              length: 6,
              controller: smsController,
              keyboardType: TextInputType.number,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(5),
                fieldHeight: 50,
                fieldWidth: 40,
                activeColor: Colors.orange.shade400,
                inactiveColor: Colors.orange.shade400,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: verifyOtp,
              child: const Text('Verify Code'),
            ),
          ],
        ),
      ),
    );
  }
}