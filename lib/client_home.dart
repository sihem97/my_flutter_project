import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_details.dart';
import 'apprentissage_selection.dart';
import 'my_requests.dart';
import 'setting_screen.dart';
import 'sign_in.dart';
import 'worker_profile.dart';
import 'contact_us.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  _ClientHomePageState createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  String clientName = "Client";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, String>> services = [
    {'name': 'Plomberie', 'image': 'assets/plumbing.jpg'},
    {'name': 'Jardinage', 'image': 'assets/gardening.jpg'},
    {'name': 'Electricite', 'image': 'assets/electricity.jpg'},
    {'name': 'Nettoyage', 'image': 'assets/nettoyage.jpg'},
    {'name': 'Peinture', 'image': 'assets/peinture.jpg'},
    {'name': 'Apprentissage', 'image': 'assets/apprentissage.jpg'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchClientName();
  }

  void _fetchClientName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        setState(() {
          clientName = doc.data()!['name'] ?? "Client";
        });
      }
    }
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const SignInScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Available Services',
          style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Text("Menu", style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkerProfileScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: const Text('Contactez Nous'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactUsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: const Text('My Requests'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MyRequestsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Accepted Requests'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AcceptedRequestsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _signOut(context),
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.white,
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20.0,
            mainAxisSpacing: 20.0,
          ),
          padding: const EdgeInsets.all(20.0),
          itemCount: services.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                if (services[index]['name'] == 'Apprentissage') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ApprentissageSelectionScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServiceDetailsScreen(
                        service: services[index]['name']!,
                      ),
                    ),
                  );
                }
              },
              child: AnimatedScale(
                scale: 1.05,
                duration: const Duration(milliseconds: 200),
                child: Card(
                  elevation: 8.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  shadowColor: Colors.red,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          services[index]['image']!,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 10.0,
                          left: 10.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Text(
                              services[index]['name']!,
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Accepted Requests Screen for Clients
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
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('userId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'In Progress')
            .snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
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
              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                child: ListTile(
                  title: Text("Service: ${doc['service']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Description: ${doc['description']}"),
                      Text("Status: ${doc['status']}"),
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