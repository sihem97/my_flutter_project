import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
        title: Text(widget.isWorker ? 'Complete Request' : 'Confirm Completion'),
        backgroundColor: Colors.red[800],
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
            // Worker View
            return _buildWorkerView(status, request);
          } else {
            // Customer View
            return _buildCustomerView(status);
          }
        },
      ),
    );
  }

  Widget _buildWorkerView(String status, DocumentSnapshot request) {
    switch (status) {
      case 'In Progress':
        return _buildWorkerInProgressView();
      case 'Worker Completed':
        return _buildWorkerWaitingForConfirmationView();
      case 'Completed':
        return _buildWorkerCompletedView(request);
      default:
        return const Center(child: Text('Unknown status'));
    }
  }

  Widget _buildCustomerView(String status) {
    switch (status) {
      case 'Worker Completed':
        return _buildCustomerReviewView();
      case 'Completed':
        return _buildCustomerCompletedView();
      default:
        return const Center(child: Text('Waiting for worker to mark as completed...'));
    }
  }

  Widget _buildWorkerInProgressView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Have you completed this service?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _markAsCompleted(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Mark as Completed', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerWaitingForConfirmationView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, color: Colors.orange, size: 48),
          SizedBox(height: 16),
          Text('Waiting for customer confirmation...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildWorkerCompletedView(DocumentSnapshot request) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 16),
          const Text('Service Completed!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (request['rating'] != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Rating: ${request['rating']}/5',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          if (request['review'] != null && request['review'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Review: ${request['review']}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerReviewView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please rate and review the service:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            decoration: const InputDecoration(
              labelText: 'Write a review (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _rating > 0 ? () => _confirmCompletion() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm Completion', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCompletedView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 48),
          SizedBox(height: 16),
          Text('Service Completed!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _markAsCompleted() async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({'status': 'Worker Completed'});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request marked as completed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmCompletion() async {
    try {
      await FirebaseFirestore.instance.collection('requests').doc(widget.requestId).update({
        'status': 'Completed',
        'rating': _rating,
        'review': _reviewController.text.trim(),
        'completedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your review!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}