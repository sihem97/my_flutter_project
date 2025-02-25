import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherDetailsScreen extends StatefulWidget {
  final QueryDocumentSnapshot teacher;

  const TeacherDetailsScreen({Key? key, required this.teacher}) : super(key: key);

  @override
  _TeacherDetailsScreenState createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen> {
  bool _showContact = false;

  @override
  Widget build(BuildContext context) {
    var teacher = widget.teacher;

    return Scaffold(
      appBar: AppBar(
        title: Text(teacher['name']),
        backgroundColor: Colors.red.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nom: ${teacher['name']}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Expérience: ${teacher['experience'] ?? 'Non spécifiée'}"),
            const SizedBox(height: 10),
            Text("Matières enseignées: ${(teacher['subjects'] as List).join(', ')}"),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
              ),
              onPressed: () {
                setState(() {
                  _showContact = true;
                });
              },
              child: const Text("Réserver"),
            ),
            if (_showContact) ...[
              const SizedBox(height: 10),
              Text("Téléphone: ${teacher['phone']}", style: const TextStyle(fontSize: 16)),
              Text("Email: ${teacher['email']}", style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
