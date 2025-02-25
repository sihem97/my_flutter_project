import 'package:flutter/material.dart';
import 'subscription.dart';
import 'client_sign_up.dart';
import 'worker_sign_up.dart';
import 'l10n/app_localizations.dart'; // ✅ Import localization

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade800,
        elevation: 0, // Remove shadow for a flat modern look
      ),
      body: Column(
        children: [
          // Upper half: Worker role
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SubscriptionInfoScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(16), // Add margin for spacing
                decoration: BoxDecoration(
                  color: Colors.red.shade800,
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4), // Subtle shadow
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Worker illustration (white icon)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.4), // Subtle overlay
                        ),
                        padding: const EdgeInsets.all(16),
                        child: const Icon(
                          Icons.handyman,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16), // Space between icon and text
                    // Right: Texts for worker role
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 7), // Add left padding to move text to the left
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).translate('worker_question'),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500, // Medium weight
                              ),
                            ),
                            const SizedBox(height: 8), // Space between texts
                            Text(
                              AppLocalizations.of(context).translate('worker_signup'),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Lower half: Client role
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ClientSignUpScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.all(16), // Add margin for spacing
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4), // Subtle shadow
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left: Texts for client role
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context).translate('client_question'),
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500, // Medium weight
                              ),
                            ),
                            const SizedBox(height: 8), // Space between texts
                            Text(
                              AppLocalizations.of(context).translate('client_signup'),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16), // Space between text and icon
                    // Right: Client illustration (white icon with red outline)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.shade800.withOpacity(0.1), // Subtle overlay
                          border: Border.all(
                              color: Colors.red.shade800, width: 2),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          Icons.person_outline,
                          size: 60,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
