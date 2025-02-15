import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'otp.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String userId;
  final bool isClient;

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.userId,
    required this.isClient,
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  late String verificationId;

  @override
  void initState() {
    super.initState();
    sendOtp(); // Automatically send OTP when screen loads
  }

  void sendOtp() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Verification failed.')),
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          this.verificationId = verificationId;
        });
        // Navigate to OTP screen immediately after sending the OTP
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              verificationID: verificationId,
              userId: widget.userId,
              isClient: widget.isClient,
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        this.verificationId = verificationId;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Verification')),
      body: Center(
        child: CircularProgressIndicator(), // Show loading while OTP is sent
      ),
    );
  }
}
