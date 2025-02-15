import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BidsScreen extends StatefulWidget {
  final String requestId;

  const BidsScreen({super.key, required this.requestId});

  @override
  _BidsScreenState createState() => _BidsScreenState();
}

class _BidsScreenState extends State<BidsScreen> {
  bool _isSnackBarShown = false;

  @override
  Widget build(BuildContext context) {
    // Debug: Print the requestId to verify it's correct
    print("Request ID in BidsScreen: ${widget.requestId}");

    return Scaffold(
      appBar: AppBar(title: const Text('Bids for Your Request')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('bids')
            .where('requestId', isEqualTo: widget.requestId) // Ensure this matches the requestId
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bids = snapshot.data!.docs;

          // Debug: Print the bids to verify they are correct
          print("Bids for Request ID ${widget.requestId}: ${bids.map((bid) => bid.data()).toList()}");

          // Check if any bid is already accepted
          QueryDocumentSnapshot? acceptedBid;
          for (var bid in bids) {
            if (bid['status'] == 'accepted') {
              acceptedBid = bid;
              break;
            }
          }

          // Show SnackBar only once when a bid is accepted
          if (acceptedBid != null && !_isSnackBarShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Bid accepted! Worker will be notified."),
                ),
              );
              setState(() {
                _isSnackBarShown = true; // Update the state
              });
            });
          }

          if (bids.isEmpty) {
            return const Center(child: Text("No bids received yet."));
          }

          return ListView.builder(
            itemCount: bids.length,
            itemBuilder: (context, index) {
              final bid = bids[index];
              String workerId = bid['workerId'];
              String workerName = bid['workerName'];
              String workerPhone = "Loading...";
              double price = bid['price'];

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(workerId).get(),
                builder: (context, workerSnapshot) {
                  if (workerSnapshot.hasData && workerSnapshot.data!.exists) {
                    workerPhone = workerSnapshot.data!['phone'] ?? "No phone available";
                  }

                  // Check if this bid is the accepted one
                  bool isAccepted = bid.id == acceptedBid?.id;

                  return Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 4,
                    color: isAccepted ? Colors.green.shade100 : null,
                    child: ListTile(
                      title: Text("Worker: $workerName"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Price: \$${price.toStringAsFixed(2)}"),
                          Text("Phone: $workerPhone"),
                          if (isAccepted)
                            const Text(
                              "Accepted",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                      trailing: isAccepted
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : ElevatedButton(
                        onPressed: acceptedBid != null
                            ? null // Disable if another bid is already accepted
                            : () async {
                          // Debug: Print the requestId and workerId before updating
                          print("Updating request: ${widget.requestId} with worker: $workerId");

                          // Update the request status and selected worker
                          await FirebaseFirestore.instance
                              .collection('requests')
                              .doc(widget.requestId)
                              .update({
                            'status': 'In Progress',
                            'selectedWorkerId': workerId,
                          });

                          // Update the bid status to "accepted"
                          await FirebaseFirestore.instance
                              .collection('bids')
                              .doc(bid.id)
                              .update({'status': 'accepted'});
                        },
                        child: const Text("Accept"),
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