import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ECGDetailPage extends StatefulWidget {
  final Map<String, dynamic> test;
  const ECGDetailPage({super.key, required this.test});

  @override
  State<ECGDetailPage> createState() => _ECGDetailPageState();
}

class _ECGDetailPageState extends State<ECGDetailPage> {
  final storage = const FlutterSecureStorage();
  final GlobalKey _ecgKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  List<FlSpot> spots = [];
  int? calculatedBPM;

  @override
  void initState() {
    super.initState();
    _fetchTestData();
  }

  int calculateBPMFromSpots(List<FlSpot> spots,
      {double threshold = 800, int minIntervalMs = 300}) {
    if (spots.length < 2) return 0;
    List<double> rPeaksX = [];
    double lastPeakX = -10000;
    for (int i = 1; i < spots.length - 1; i++) {
      double prev = spots[i - 1].y;
      double curr = spots[i].y;
      double next = spots[i + 1].y;
      if (curr > threshold && curr > prev && curr > next) {
        if (((spots[i].x - lastPeakX) / 250.0 * 1000) > minIntervalMs) {
          rPeaksX.add(spots[i].x);
          lastPeakX = spots[i].x;
        }
      }
    }
    if (rPeaksX.length < 2) return 0;
    List<double> intervals = [];
    for (int i = 1; i < rPeaksX.length; i++) {
      intervals.add((rPeaksX[i] - rPeaksX[i - 1]) / 250.0);
    }
    double meanInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    return meanInterval > 0 ? (60 / meanInterval).round() : 0;
  }

  Future<void> _fetchTestData() async {
    print("ID du test : ${widget.test['id']}");
    String? token = await storage.read(key: 'access_token');
    try {
      final response = await http.get(
        Uri.parse(
            'https://cardiotrack-server.onrender.com/data/${widget.test['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final signalData = data['signal_data'] as List<dynamic>;

        setState(() {
          spots = convertToSpots(signalData);
          calculatedBPM = calculateBPMFromSpots(spots);
        });

        // Scroll automatiquement pour que le graphe soit peint
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
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
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: RepaintBoundary(
        key: _ecgKey,
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
      ),
    );
  }

  Future<void> _shareGraph() async {
  try {
    await Future.delayed(const Duration(milliseconds: 500));

    final boundary =
        _ecgKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    if (boundary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur : graphe non disponible.")),
      );
      return;
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/ecg_graph.png').create();
    await file.writeAsBytes(pngBytes);

    // Ajoute la date et l'heure dans le texte partagé
    final date = widget.test['timestamp'] ?? '';
    final bpm = calculatedBPM ?? '-';
    final shareText = 'Test ECG\nDate : $date\nRythme : $bpm bpm\nGénéré avec Cardio Track.';

    await Share.shareXFiles(
      [XFile(file.path)],
      text: shareText,
    );
  } catch (e) {
    print("Erreur lors du partage : $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur lors du partage : $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails du test ECG',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.red[400],
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareGraph,
          ),
        ],
        
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Date : ${widget.test['timestamp']}",
                style: const TextStyle(fontSize: 18)),
            Text("Rythme : ${calculatedBPM ?? '-'} bpm",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text("Signal ECG :",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            buildECGGraph(),
          ],
        ),
      ),
    );
  }
}
