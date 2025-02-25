import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bids_screen.dart';
import 'l10n/app_localizations.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Demandes'),
        backgroundColor: Colors.red.shade800,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('userId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'pending') // Only pending requests
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("Aucune demande trouvée."));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              String requestId = doc.id;
              String status = doc['status'];

              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                color: Colors.white,
                child: ListTile(
                  title: Text(
                    // Display the service in a localized way:
                    AppLocalizations.of(context).translate(doc['service']),
                    style: const TextStyle(color: Colors.red),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Description: ${doc['description']}"),
                      Text(
                        "Statut: $status",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  trailing:StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('bids')
                        .where('requestId', isEqualTo: requestId)
                        .snapshots(), // ✅ Change .get() to .snapshots() for real-time updates
                    builder: (context, AsyncSnapshot<QuerySnapshot> bidSnapshot) {
                      if (bidSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      final bidDocs = bidSnapshot.data?.docs ?? [];

                      if (bidDocs.isNotEmpty) {
                        return TextButton(
                          child: const Text(
                            "Voir les Offres",
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            print("Navigation vers BidsScreen avec l'ID de la demande: $requestId");
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BidsScreen(requestId: requestId),
                              ),
                            );
                          },
                        );
                      } else {
                        return IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
                          },
                        );
                      }
                    },
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
