import 'package:flutter/material.dart';
import 'worker_sign_up.dart';
import 'l10n/app_localizations.dart'; // ✅ Import localization

class SubscriptionInfoScreen extends StatelessWidget {
  const SubscriptionInfoScreen({Key? key}) : super(key: key);

  // The available subscriptions (informational only)
  final List<Map<String, dynamic>> subscriptions = const [
    {
      "duration": "1_month",
      "totalCost": 3500,
      "costPerMonth": 3500,
    },
    {
      "duration": "3_months",
      "totalCost": 9000,
      "costPerMonth": 3000,
    },
    {
      "duration": "6_months",
      "totalCost": 17000,
      "costPerMonth": 2833,
    },
    {
      "duration": "1_year",
      "totalCost": 22000,
      "costPerMonth": 1833,
    },
  ];

  @override
  Widget build(BuildContext context) {
    String currency = AppLocalizations.of(context).translate('currency'); // ✅ Get currency dynamically

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('subscriptions_available')),
        backgroundColor: Colors.red.shade800,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                final subscription = subscriptions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                              .translate(subscription["duration"]),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${AppLocalizations.of(context).translate('total_cost')}: ${subscription["totalCost"]} $currency",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${AppLocalizations.of(context).translate('cost_per_month')}: ${subscription["costPerMonth"]} $currency",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // Navigate to the Worker sign-up screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WorkerSignUpScreen(),
                    ),
                  );
                },
                child: Text(
                  AppLocalizations.of(context).translate('next'),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
