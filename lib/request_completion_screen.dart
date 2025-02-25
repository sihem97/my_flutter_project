import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'l10n/app_localizations.dart';

class RequestCompletionScreen extends StatefulWidget {
  final String requestId;
  final String workerId;
  final bool isWorker;

  const RequestCompletionScreen({
    Key? key,
    required this.requestId,
    required this.workerId,
    required this.isWorker,
  }) : super(key: key);

  @override
  State<RequestCompletionScreen> createState() => _RequestCompletionScreenState();
}

class _RequestCompletionScreenState extends State<RequestCompletionScreen> {
  double _rating = 0;
  final _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isWorker
            ? AppLocalizations.of(context).translate('complete_request')
            : AppLocalizations.of(context).translate('confirm_completion')),
        backgroundColor: Colors.red.shade800,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .doc(widget.requestId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final request = snapshot.data!;
          final status = request['status'];

          if (widget.isWorker) {
            return _buildWorkerView(status);
          } else {
            return _buildCustomerView(status);
          }
        },
      ),
    );
  }

  Widget _buildWorkerView(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).translate('waiting_for_customer_confirmation'),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerView(String status) {
    if (status == 'Worker Completed') {
      return _buildCustomerReviewView();
    } else if (status == 'Completed') {
      return _buildCustomerCompletedView();
    } else {
      return Center(
        child: Text(
          AppLocalizations.of(context).translate('waiting_for_worker_completion'),
        ),
      );
    }
  }

  Widget _buildCustomerReviewView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).translate('please_rate_review_service'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              );
            }),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('write_review_optional'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _rating > 0 ? () => _confirmCompletion() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).translate('confirm_completion_button'),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCompletedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).translate('service_completed'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCompletion() async {
    try {
      // Update the request document to mark it as completed.
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
        'status': 'Completed',
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'completedAt': FieldValue.serverTimestamp(),
      });

      // Add a review document in the "reviews" collection.
      final clientId = FirebaseAuth.instance.currentUser?.uid;
      await FirebaseFirestore.instance.collection('reviews').add({
        'workerId': widget.workerId,
        'clientId': clientId,
        'requestId': widget.requestId,
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('thank_you_for_review')),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${AppLocalizations.of(context).translate('error')}: $e"),
        ),
      );
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
