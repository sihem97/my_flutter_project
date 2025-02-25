import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_home.dart';
import 'l10n/app_localizations.dart';

class BidsScreen extends StatefulWidget {
  final String requestId;

  const BidsScreen({Key? key, required this.requestId}) : super(key: key);

  @override
  _BidsScreenState createState() => _BidsScreenState();
}

class _BidsScreenState extends State<BidsScreen> {
  bool _isSnackBarShown = false;

  /// This function fetches all review documents for a given workerId,
  /// calculates and returns the average rating.
  Future<double> _getWorkerRating(String workerId) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('workerId', isEqualTo: workerId)
        .get();
    if (snapshot.docs.isEmpty) {
      return 0.0;
    }
    double sum = 0.0;
    for (var doc in snapshot.docs) {
      sum += (doc['rating'] as num).toDouble();
    }
    return sum / snapshot.docs.length;
  }

  /// Helper method to build star icons based on rating.
  Widget _buildStarIcons(double rating) {
    int fullStars = rating.floor();
    bool halfStar = (rating - fullStars) >= 0.5;
    List<Widget> stars = [];
    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 16));
    }
    if (halfStar) {
      stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 16));
    }
    // Optionally fill with empty stars to show a 5-star scale.
    while (stars.length < 5) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 16));
    }
    return Row(children: stars);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('bids')),
        backgroundColor: Colors.red.shade800,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('bids')
            .where('requestId', isEqualTo: widget.requestId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bids = snapshot.data!.docs;

          // Look for an accepted bid
          QueryDocumentSnapshot? acceptedBid;
          for (var bid in bids) {
            if (bid['status'] == 'accepted') {
              acceptedBid = bid;
              break;
            }
          }

          if (acceptedBid != null && !_isSnackBarShown) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)
                      .translate('bid_accepted')),
                ),
              );
              setState(() {
                _isSnackBarShown = true;
              });
            });
          }

          if (bids.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)
                  .translate('no_bids')),
            );
          }

          return ListView.builder(
            itemCount: bids.length,
            itemBuilder: (context, index) {
              final bid = bids[index];
              String workerName = bid['workerName'];
              double price = bid['price'];
              String workerId = bid['workerId'];
              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                color: acceptedBid?.id == bid.id
                    ? Colors.green.shade100
                    : null,
                child: ListTile(
                  title: Text(
                      "${AppLocalizations.of(context).translate('worker')}: $workerName"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "${AppLocalizations.of(context).translate('price')}: ${price.toStringAsFixed(2)}"),
                      // Use a FutureBuilder to fetch and display the average rating with star icons.
                      FutureBuilder<double>(
                        future: _getWorkerRating(workerId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Text(AppLocalizations.of(context)
                                .translate('loading_rating'));
                          } else if (snapshot.hasError) {
                            return Text(AppLocalizations.of(context)
                                .translate('rating_error'));
                          } else {
                            double rating = snapshot.data ?? 0.0;
                            return Row(
                              children: [
                                Text(rating.toStringAsFixed(1)),
                                const SizedBox(width: 4),
                                _buildStarIcons(rating),
                              ],
                            );
                          }
                        },
                      ),
                      if (acceptedBid?.id == bid.id)
                        Text(
                          AppLocalizations.of(context).translate('accepted'),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                    ],
                  ),
                  trailing: acceptedBid != null
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : ElevatedButton(
                    onPressed: () async {
                      // Update the bid status to 'accepted'
                      await FirebaseFirestore.instance
                          .collection('bids')
                          .doc(bid.id)
                          .update({'status': 'accepted'});

                      // Update the corresponding request document with workerId and status
                      await FirebaseFirestore.instance
                          .collection('requests')
                          .doc(widget.requestId)
                          .update({
                        'workerId': bid['workerId'],
                        'status': 'accepted'
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)
                              .translate('bid_confirmed')),
                        ),
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            const AcceptedRequestsScreen()),
                      );
                    },
                    child: Text(AppLocalizations.of(context)
                        .translate('accept')),
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
