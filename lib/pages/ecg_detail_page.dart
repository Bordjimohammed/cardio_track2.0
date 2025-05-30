import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


class ECGDetailPage extends StatefulWidget {
  final Map<String, dynamic> test;
  const ECGDetailPage({super.key, required this.test});
  @override
  State<ECGDetailPage> createState() => _ECGDetailPageState();
}
class _ECGDetailPageState extends State<ECGDetailPage> {
  final storage = const FlutterSecureStorage();
  List<FlSpot> spots = [];


  @override
  void initState() {
    super.initState();
    _fetchTestData();
  }

  Future<void> _fetchTestData() async {
    print("ID du test : ${widget.test['id']}");
    String? token = await storage.read(key: 'access_token');
    try {
      final id = widget.test['id']; // <- ici on extrait l'id du test
      final response = await http.get(
        Uri.parse('https://cardiotrack-server.onrender.com/data/${widget.test['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      print("Réponse brute : ${response.body}");


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final signalData = data['signal_data'] as List<dynamic>;

        setState(() {
          spots = convertToSpots(signalData);
        });
      } else {
        print("Erreur ${response.statusCode} lors du chargement du test.");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  List<FlSpot> convertToSpots(List<dynamic>? signalData) {
    if (signalData == null) return [];

    return signalData.map<FlSpot>((point) {
      final x = point['x']?.toDouble() ?? 0.0;
      final y = point['y']?.toDouble() ?? 0.0;
      return FlSpot(x, y);
    }).toList();
  }

  Widget buildECGGraph() {
    if (spots.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final double chartWidth = (spots.length * 5).toDouble().clamp(300, 10000);

return SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: SizedBox(
    width: chartWidth,
    height: 200,
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    ),
  ),
);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            ' Details du test ECG',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.red[400],
        ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date : ${widget.test['timestamp']}", style: const TextStyle(fontSize: 18)),
            Text("Rythme : ${widget.test['rythme']} bpm", style: const TextStyle(fontSize: 18)),
            Text("Statut : ${widget.test['status']}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text("Signal ECG :", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildECGGraph(),
          ],
        ),
      ),
    );
  }
}

