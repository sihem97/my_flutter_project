import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'l10n/app_localizations.dart';

class AcceptedReservationsScreen extends StatefulWidget {
  const AcceptedReservationsScreen({Key? key}) : super(key: key);

  @override
  _AcceptedReservationsScreenState createState() => _AcceptedReservationsScreenState();
}

class _AcceptedReservationsScreenState extends State<AcceptedReservationsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _formatTimestamp(DateTime dateTime) {
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} - ${dateTime.hour}:${dateTime.minute}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('accepted_reservations')),
        backgroundColor: Colors.red.shade800,
      ),
      body: _currentUser == null
          ? Center(
        child: Text(AppLocalizations.of(context).translate('please_sign_in')),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('reservations')
            .where('teacherId', isEqualTo: _currentUser!.uid)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(context).translate('error_loading_data'),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context).translate('no_accepted_reservations'),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final reservation = snapshot.data!.docs[index];
              final reservationData = reservation.data() as Map<String, dynamic>;
              final String clientId = reservationData['clientId'] ?? '';
              final Timestamp timestamp = reservationData['timestamp'] as Timestamp? ??
                  Timestamp.now();
              final DateTime reservationTime = timestamp.toDate();

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(clientId).get(),
                builder: (context, clientSnapshot) {
                  if (clientSnapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      margin: EdgeInsets.all(10),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }

                  String clientName = 'Unknown';
                  if (clientSnapshot.hasData && clientSnapshot.data!.exists) {
                    final clientData = clientSnapshot.data!.data() as Map<String, dynamic>?;
                    clientName = clientData?['fullName'] ?? 'Unknown';
                  }

                  return Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${AppLocalizations.of(context).translate("")} $clientName",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (reservationData.containsKey('subject') &&
                              reservationData['subject'] != null)
                            Text(
                              "${AppLocalizations.of(context).translate('subject')}: ${reservationData['subject']}",
                            ),
                          const SizedBox(height: 4),
                          if (reservationData.containsKey('notes') &&
                              reservationData['notes'] != null)
                            Text(
                              "${AppLocalizations.of(context).translate('notes')}: ${reservationData['notes']}",
                            ),
                          const SizedBox(height: 4),
                          Text(
                            "${AppLocalizations.of(context).translate('reservation_time')}: ${_formatTimestamp(reservationTime)}",
                          ),
                          const SizedBox(height: 12),
                          if (reservationData.containsKey('contactInfo') &&
                              reservationData['contactInfo'] != null)
                            Text(
                              "${AppLocalizations.of(context).translate('contact_info')}: ${reservationData['contactInfo']}",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  await _firestore
                                      .collection('reservations')
                                      .doc(reservation.id)
                                      .update({'status': 'completed'});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        AppLocalizations.of(context)
                                            .translate('reservation_marked_as_completed'),
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: Text(
                                  AppLocalizations.of(context).translate('mark_as_completed'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  // Show confirmation dialog before cancelling
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                          AppLocalizations.of(context)
                                              .translate('confirm_cancellation'),
                                        ),
                                        content: Text(
                                          AppLocalizations.of(context)
                                              .translate('cancel_reservation_confirmation'),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text(
                                              AppLocalizations.of(context).translate('no'),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              await _firestore
                                                  .collection('reservations')
                                                  .doc(reservation.id)
                                                  .update({'status': 'cancelled'});
                                              Navigator.of(context).pop();
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    AppLocalizations.of(context)
                                                        .translate('reservation_cancelled'),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              AppLocalizations.of(context).translate('yes'),
                                              style: TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text(
                                  AppLocalizations.of(context).translate('cancel'),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
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