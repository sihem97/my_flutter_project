import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pending_confirmations_screen.dart';
import 'l10n/app_localizations.dart';

class AcceptedRequestsScreen extends StatelessWidget {
  const AcceptedRequestsScreen({Key? key}) : super(key: key);

  // Function to format timestamp
  String _formatTimestamp(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute}";
  }

  // Function to make a phone call
  void _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint("Could not launch phone call");
    }
  }

  // Function to calculate distance between worker and client
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const int R = 6371; // Earth's radius in km
    double dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    double dLon = (lon2 - lon1) * (3.141592653589793 / 180);

    double a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1 * (3.141592653589793 / 180)) *
            cos(lat2 * (3.141592653589793 / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in km
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('accepted_requests')),
        backgroundColor: Colors.red.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('workerId', isEqualTo: user?.uid)
            .where('status', whereIn: ['accepted'])
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "${AppLocalizations.of(context).translate('error')}: ${snapshot.error}",
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context).translate('no_accepted_requests'),
              ),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final String requestId = request.id;
              final String status = request['status'];
              final String userId = request['userId']; // Get client ID

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                builder: (context, clientSnapshot) {
                  if (!clientSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final clientData = clientSnapshot.data!;
                  final String clientName = clientData['fullName'] ?? 'Unknown';
                  final String clientPhone = clientData['phone'] ?? 'N/A';

                  final Timestamp? timestamp = request['timestamp'];
                  DateTime requestTime = timestamp != null ? timestamp.toDate() : DateTime.now();


                  return Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${AppLocalizations.of(context).translate('client')}: $clientName",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${AppLocalizations.of(context).translate('description')}: ${request['description']}",
                          ),
                          const SizedBox(height: 8),

                          Text(
                            "${AppLocalizations.of(context).translate('request_time')}: ${_formatTimestamp(requestTime)}",
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              _makePhoneCall(clientPhone);
                            },
                            child: Text(
                              "${AppLocalizations.of(context).translate('phone')}: $clientPhone",
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () async {
                              bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(
                                      AppLocalizations.of(context).translate('confirm_completion'),
                                    ),
                                    content: Text(
                                      AppLocalizations.of(context).translate('confirm_completion_message'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                        child: Text(AppLocalizations.of(context).translate('cancel')),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                        child: Text(AppLocalizations.of(context).translate('confirm')),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirm != true) return;

                              try {
                                await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
                                  'status': 'Worker Completed',
                                  'completedAt': FieldValue.serverTimestamp(),
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context).translate('request_marked_completed')),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PendingConfirmationsScreen(),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "${AppLocalizations.of(context).translate('error')}: $e",
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade800,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(AppLocalizations.of(context).translate('mark_as_completed')),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
