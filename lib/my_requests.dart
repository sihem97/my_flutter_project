import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bids_screen.dart';

class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Requests')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('userId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'pending')  // Only show pending requests
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          if (requests.isEmpty) {
            return const Center(child: Text("No requests found."));
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
                child: ListTile(
                  title: Text("${doc['service']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Description: ${doc['description']}"),
                      Text("Status: $status", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: status == "Pending"
                      ? IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('requests').doc(requestId).delete();
                    },
                  )
                      : FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('bids')
                        .where('requestId', isEqualTo: requestId)
                        .get(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> bidSnapshot) {
                      if (bidSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator(); // Show loader while checking for bids
                      }

                      if (!bidSnapshot.hasData || bidSnapshot.data!.docs.isEmpty) {
                        return const SizedBox(); // Hide the button if no bids
                      }

                      return TextButton(
                        child: const Text("View Bids"),
                        onPressed: () {
                          print("Navigating to BidsScreen with Request ID: $requestId");
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BidsScreen(requestId: requestId),
                            ),
                          );
                        },
                      );
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
