import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:Cardio_Track/navbar/navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import '../pages/ecg_detail_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DashboardPage extends StatefulWidget {
  final String userEmail;
  const DashboardPage({super.key, required this.userEmail});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> historique = [];
  // Map to store a unique GlobalKey for each test's ECG graph
  final Map<int, GlobalKey> _graphKeys = {};

  List<FlSpot> decodeECGData(List<dynamic>? rawData) {
    if (rawData == null) return [];
    return rawData.map<FlSpot>((point) {
      final x = point['x']?.toDouble() ?? 0.0;
      final y = point['y']?.toDouble() ?? 0.0;
      return FlSpot(x, y);
    }).toList();
  }

  Widget buildECGGraph(List<FlSpot> spots) {
  if (spots.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }
  // Largeur dynamique : 5 pixels par point, minimum 300
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

  List<FlSpot> convertToSpots(List<dynamic>? signalData) {
    if (signalData == null) return [];

    return signalData.map<FlSpot>((point) {
      final x = point['x']?.toDouble() ?? 0.0;
      final y = point['y']?.toDouble() ?? 0.0;
      return FlSpot(x, y);
    }).toList();
  }
  Future<void> _deleteTest(int id) async {
    String? token = await storage.read(key: 'access_token');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ce test ?'),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse('https://cardiotrack-server.onrender.com/delete_data/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          historique.removeWhere((test) => test['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test supprimé avec succès')),
        );
      } else {
        throw Exception("Erreur lors de la suppression");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }
Future<void> _shareTest(Map<String, dynamic> test, GlobalKey key) async {
  try {
    if (key.currentContext == null) {
      // Essai de rendre le widget visible en scrollant automatiquement
      await Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Vérifier encore après scroll
    if (key.currentContext == null) {
      throw Exception(
        'Le graphe n\'est pas encore prêt à être partagé. Faites défiler la carte pour afficher le graphe puis réessayez.'
      );
    }

    await Future.delayed(const Duration(milliseconds: 300)); // Laisser le temps au rendu

    RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    if (boundary.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/ecg_${test['id']}.png').create();
    await file.writeAsBytes(pngBytes);

    final date = test['timestamp'] ?? '';
    final rythme = test['rythme']?.toString() ?? '';
    final status = test['status'] ?? '';
    final shareText = 'ECG Test\nDate: $date\nRythme: $rythme\nStatus: $status';

    await Share.shareXFiles([XFile(file.path)], text: shareText);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur lors du partage : $e')),
    );
  }
}

  //final storage = const FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    String? token = await storage.read(
        key:
        'access_token');
    try {
      final response = await http.get(
        Uri.parse('https://cardiotrack-server.onrender.com/list_data'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          historique = data.cast<Map<String, dynamic>>();
        });
      } else {
        print("Erreur lors du chargement de l'historique");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  void _openDetails(Map<String, dynamic> test) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ECGDetailPage(test: test),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavBar()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Historique ECG',
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
          child: historique.isEmpty
              ? Center(
            child: Text(
              "Aucun test enregistré pour le moment.",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          )
              : ListView.builder(
            itemCount: historique.length,
            itemBuilder: (context, index) {
              final test = historique[index];
              final List<FlSpot> signalSpots = convertToSpots(test['signal']);
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.monitor_heart,
                          color: Colors.red[300], size: 30),
                      title: Text("Test du ${test['timestamp']}"),
                      subtitle: Text("Statut :${test['status']}"),                 
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTest(test['id']),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Colors.grey),
                        ],
                      ),
                      onTap: () => _openDetails(test),
                    ),
                    if (test['signal'] != null && test['signal'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8),
                    child: RepaintBoundary(
                      key: _graphKeys.putIfAbsent(test['id'], () => GlobalKey()),
                      child: buildECGGraph(decodeECGData(test['signal'])),
                    ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

}
