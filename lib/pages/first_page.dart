import 'dart:convert';

import 'package:Cardio_Track/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
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
  @override
  void initState() {
    super.initState();
    _loadUserData(); // Chargement des données utilisateur
  }

  Future<void> _loadUserData() async {
    String? token = await storage.read(
        key:
            'access_token'); /*
    String? name = await storage.read(key: 'user_name');
    String? rate = await storage.read(key: 'heart_rate');
    String? pressure = await storage.read(key: 'blood_pressure');
*/
    final response = await http.get(
      Uri.parse("http://192.168.43.40:5000/me"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      name = data['name'];
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['error'])),
      );
    }

    setState(() {
      name ?? 'Utilisateur';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cardio Track'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour ${name ?? ''} 👋',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Suivi de votre santé cardiaque',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
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
