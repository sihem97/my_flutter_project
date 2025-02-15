import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'request_completion_screen.dart'; // Import the RequestCompletionScreen

class AcceptedRequestsScreen extends StatelessWidget {
  const AcceptedRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accepted Requests'),
        backgroundColor: Colors.red.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('selectedWorkerId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'In Progress') // Only show accepted requests
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final requests = snapshot.data!.docs;
          if (requests.isEmpty) {
            return const Center(child: Text("No accepted requests yet."));
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
                  title: Text("Service: ${doc['service']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Description: ${doc['description']}"),
                      Text("Status: ${doc['status']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      try {
                        // Update the status to "Worker Completed"
                        await FirebaseFirestore.instance.collection('requests').doc(requestId).update({
                          'status': 'Worker Completed',
                        });

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Request marked as completed!")),
                        );

                        // Optionally navigate to the RequestCompletionScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RequestCompletionScreen(
                              requestId: requestId,
                              workerId: user!.uid,
                              isWorker: true,
                            ),
                          ),
                        );
                      } catch (e) {
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Mark as Completed"),
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