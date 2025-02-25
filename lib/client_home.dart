import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'client_profile.dart';
import 'pending_requests_screen.dart';
import 'accepted_requests_screen.dart';
import 'main.dart';
import 'HistoryScreen.dart';
import 'service_details.dart';
import 'apprentissage_selection.dart';
import 'my_requests.dart';
import 'setting_screen.dart';
import 'sign_in.dart';
import 'worker_profile.dart';
import 'contact_us.dart';
import 'l10n/app_localizations.dart'; // ✅ Import localization

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  _ClientHomePageState createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, String>> services = [
    {'key': 'plumbing', 'image': 'assets/plumbing.jpg'},
    {'key': 'gardening', 'image': 'assets/gardening.jpg'},
    {'key': 'electricity', 'image': 'assets/electricity.jpg'},
    {'key': 'cleaning', 'image': 'assets/nettoyage.jpg'},
    {'key': 'painting', 'image': 'assets/peinture.jpg'},
    {'key': 'apprenticeship', 'image': 'assets/apprentissage.jpg'},
  ];

  int _currentIndex = 0;

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => SignInScreen(MyApp.of(context).setLocale)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ClientProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Colors.red[800],
              height: 120,
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  AppLocalizations.of(context).translate('menu'),
                  style: const TextStyle(color: Colors.white, fontSize: 30),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(AppLocalizations.of(context).translate('home')),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment),
              title: Text(AppLocalizations.of(context).translate('my_requests')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MyRequestsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title:
              Text(AppLocalizations.of(context).translate('accepted_requests')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AcceptedRequestsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_bottom),
              title:
              Text(AppLocalizations.of(context).translate('pending_requests')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PendingRequestsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(AppLocalizations.of(context).translate('history')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_mail),
              title: Text(AppLocalizations.of(context).translate('contact_us')),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ContactUsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16.0),
            // Green Promotional Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.all(16),
              height: 150, // Adjust height as needed
              decoration: BoxDecoration(
                color: Colors.red.shade800,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  // Text Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "MyRaha",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Vos besoins, Nos services",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  // Image Section
                  Image.asset(
                    "assets/happy.png", // Ensure this image exists in your assets
                    height: 200,
                    width: 140,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                AppLocalizations.of(context).translate('explore_services'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            // GridView of Services
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: services.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    if (services[index]['key'] == 'apprenticeship') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EducationLevelSelectionScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDetailsScreen(
                            service: services[index]['key']!,
                          ),
                        ),
                      );
                    }
                  },
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16.0),
                            ),
                            child: Image.asset(
                              services[index]['image']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(16.0),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)
                                .translate(services[index]['key']!),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class AcceptedRequestsScreen extends StatelessWidget {
  const AcceptedRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('accepted_requests')),
        backgroundColor: Colors.red.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('userId', isEqualTo: user?.uid)
            .where('status', whereIn: ['accepted', 'Accepted'])
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('${AppLocalizations.of(context).translate('error')}: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context).translate('no_accepted_requests')),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final request = docs[index].data() as Map<String, dynamic>;
              final String workerId = request['workerId'];
              final String requestId = docs[index].id; // Get the request ID

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(workerId).get(),
                builder: (context, workerSnapshot) {
                  if (!workerSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final workerData = workerSnapshot.data!;
                  final String workerName = workerData['name'] ?? 'Unknown';

                  // ✅ Fetch the agreed bid price from the bids collection
                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('bids')
                        .where('requestId', isEqualTo: requestId)
                        .where('status', isEqualTo: 'accepted')
                        .get(),
                    builder: (context, bidSnapshot) {
                      if (!bidSnapshot.hasData || bidSnapshot.data!.docs.isEmpty) {
                        return Card(
                          margin: const EdgeInsets.all(10),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${AppLocalizations.of(context).translate('worker')}: $workerName",
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${AppLocalizations.of(context).translate('service')}: ${AppLocalizations.of(context).translate(request['service'])}",
                                ),
                                Text(
                                  "${AppLocalizations.of(context).translate('description')}: ${request['description']}",
                                ),
                                Text(
                                  "${AppLocalizations.of(context).translate('status')}: ${AppLocalizations.of(context).translate(request['status'])}",
                                ),
                                Text(
                                  "${AppLocalizations.of(context).translate('agreed_bid')}: ${AppLocalizations.of(context).translate('no_bid_info')}",
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context).translate('worker_will_call'),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final bidData = bidSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                      final double bidAmount = bidData['price'];

                      return Card(
                        margin: const EdgeInsets.all(10),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${AppLocalizations.of(context).translate('worker')}: $workerName",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${AppLocalizations.of(context).translate('service')}: ${AppLocalizations.of(context).translate(request['service'])}",
                              ),
                              Text(
                                "${AppLocalizations.of(context).translate('description')}: ${request['description']}",
                              ),
                              Text(
                                "${AppLocalizations.of(context).translate('status')}: ${AppLocalizations.of(context).translate(request['status'])}",
                              ),
                              Text(
                                "${AppLocalizations.of(context).translate('agreed_bid')}: ${bidAmount.toStringAsFixed(2)} DZD",
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context).translate('worker_will_call'),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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