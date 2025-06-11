import 'dart:async';
import 'dart:convert';
import 'package:Cardio_Track/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../pages/ecg.dart';
import 'package:http/http.dart' as http;

class FirstPage extends StatefulWidget {
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  final storage = const FlutterSecureStorage();
  String? name;
  String? email;
  @override
  void initState() {
    super.initState();
    _loadUserData();// Chargement des données utilisateur

    Timer.periodic(Duration(seconds: 10), (timer) {
    if (mounted) {
      _loadUserData();
    } else {
      timer.cancel();
    }
  });
  }

Future<void> _loadUserData() async {
  String? token = await storage.read(key: 'access_token');
  final response = await http.get(
    Uri.parse("https://cardiotrack-server.onrender.com/me"),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    name = data['name'];
    email = data['email'];
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setUserName(data['name']);
    userProvider.setEmail(data['email']);
    userProvider.setPassword(data['password']);

    // Ajoute ce bloc pour récupérer le dernier BPM
    final historyResponse = await http.get(
      Uri.parse("https://cardiotrack-server.onrender.com/list_data"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (historyResponse.statusCode == 200) {
      final List<dynamic> history = jsonDecode(historyResponse.body);
      if (history.isNotEmpty) {
        final lastTest = history.last;
        final lastBpm = lastTest['rythme'] ?? lastTest['bpm'];
        Provider.of<HeartRateProvider>(context, listen: false).setHeartRate(lastBpm ?? 0);
      }
    }
  } else {
    final data = jsonDecode(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['error'])),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cardio Track",style:Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white,)
        ) ,
        centerTitle: true,
        backgroundColor: Colors.red[400],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const SizedBox(height: 30),
            _buildHealthCards(),
            const SizedBox(height: 30),
            _buildTestButton(context),
            const SizedBox(height: 30),
            _buildQuickTips(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final name = context.watch<UserProvider>().userName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour ${name} ',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Suivi de votre santé cardiaque',
            style: Theme.of(context).textTheme.bodyLarge,

        ),
      ],
    );
  }

  Widget _buildHealthCards() {
    return Consumer<HeartRateProvider>(
      builder: (context, heartRateProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color.fromARGB(
                    255, 50, 50, 50) // couleur sombre pour dark mode
                : const Color.fromARGB(
                    255, 255, 255, 255), // couleur claire pour light mode
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.favorite, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Rythme cardiaque',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
              '${heartRateProvider.heartRate}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              Text(
                'bpm',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.monitor_heart_outlined, size: 24),
        label: const Text(
          'Démarrer un test ECG',
          style: TextStyle(fontSize: 18),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.red[400],
          foregroundColor: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LiveDataChart()),
          );
        },
      ),
    );
  }

  Widget _buildQuickTips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conseils du jour',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
        ),
        const SizedBox(height: 10),
        const TipCard(
          icon: Icons.water_drop,
          title: 'Hydratation',
          content: 'Buvez au moins 2L d\'eau aujourd\'hui',
        ),
        const TipCard(
          icon: Icons.directions_walk,
          title: 'Activité',
          content: '30 minutes de marche recommandées',
        ),
      ],
    );
  }
}

// Widget personnalisé pour les indicateurs de santé
class HealthMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const HealthMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget personnalisé pour les conseils
class TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const TipCard({
    super.key,
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(content),
      ),
    );
  }
}
