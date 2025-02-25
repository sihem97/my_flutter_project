import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'request_completion_screen.dart';
import 'l10n/app_localizations.dart';

class PendingRequestsScreen extends StatelessWidget {
  const PendingRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('pending_requests')),
        backgroundColor: Colors.red.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('userId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'Worker Completed') // Show only completed requests waiting for confirmation
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "${AppLocalizations.of(context).translate('error')}: ${snapshot.error}",
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!.docs;
          if (requests.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context).translate('no_pending_requests')),
            );
          }
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              String requestId = doc.id;
              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                child: ListTile(
                  title: Text(
                    AppLocalizations.of(context).translate(doc['service']),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${AppLocalizations.of(context).translate('description')}: ${doc['description']}",
                      ),
                      Text(
                        AppLocalizations.of(context).translate('waiting_for_confirmation'),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestCompletionScreen(
                            requestId: requestId,
                            workerId: doc['workerId'], // Updated field: use 'workerId'
                            isWorker: false, // Client's view
                          ),
                        ),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('review_confirm'),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
