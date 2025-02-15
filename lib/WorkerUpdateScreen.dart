import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkerUpdateScreen extends StatefulWidget {
  final String idDemande;

  const WorkerUpdateScreen({required this.idDemande});

  @override
  _WorkerUpdateScreenState createState() => _WorkerUpdateScreenState();
}

class _WorkerUpdateScreenState extends State<WorkerUpdateScreen> {
  final TextEditingController _devisController = TextEditingController();
  String _selectedState = 'In Progress'; // Default state

  List<String> states = ['In Progress', 'Completed', 'Cancelled'];

  Future<void> _updateRequest() async {
    try {
      // Get the updated values
      final devis = _devisController.text;
      final state = _selectedState;

      // Update the Firestore document dynamically
      await FirebaseFirestore.instance.collection('requests').doc(widget.idDemande).update({
        'devis': devis.isEmpty ? 'Not defined yet' : devis,
        'state': state,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demande mise à jour avec succès!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mettre à jour la demande'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID de la demande: ${widget.idDemande}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            // Devis field
            TextField(
              controller: _devisController,
              decoration: InputDecoration(labelText: 'Devis (prix)'),
            ),
            SizedBox(height: 20),

            // State dropdown
            DropdownButtonFormField(
              value: _selectedState,
              items: states.map((String state) {
                return DropdownMenuItem(
                  value: state,
                  child: Text(state),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedState = value!;
                });
              },
              decoration: InputDecoration(labelText: 'État de la demande'),
            ),
            SizedBox(height: 20),

            // Update button
            ElevatedButton(
              onPressed: _updateRequest,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                'Mettre à jour',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}