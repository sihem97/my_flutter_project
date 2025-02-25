import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'l10n/app_localizations.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).translate('history')),
          backgroundColor: Colors.red.shade800,
        ),
        body: Center(child: Text(AppLocalizations.of(context).translate('user_not_logged_in'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('history')),
        backgroundColor: Colors.red.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('status', isEqualTo: 'Completed')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(
                    "${AppLocalizations.of(context).translate('error')}: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter results to include only those requests where
          // the current user is either the client or the worker.
          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['userId'] == user.uid || data['workerId'] == user.uid;
          }).toList();

          if (docs.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context).translate('no_history')));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                child: ListTile(
                  title: Text(
                    "${AppLocalizations.of(context).translate('service')}: ${AppLocalizations.of(context).translate(data['service'])}",
                    style: const TextStyle(color: Colors.red),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${AppLocalizations.of(context).translate('description')}: ${data['description']}",
                      ),
                      Text(
                        "${AppLocalizations.of(context).translate('status')}: ${AppLocalizations.of(context).translate(data['status'])}",
                      ),
                      if (data.containsKey('workerName'))
                        Text(
                          "${AppLocalizations.of(context).translate('worker')}: ${data['workerName']}",
                        ),
                      if (data.containsKey('clientName'))
                        Text(
                          "${AppLocalizations.of(context).translate('client')}: ${data['clientName']}",
                        ),
                    ],
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
