import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/user_provider.dart';
import 'package:provider/provider.dart'; // Importez le package provider


class LiveDataChart extends StatefulWidget {
  const LiveDataChart({super.key});

  @override
  _LiveDataChartState createState() => _LiveDataChartState();
}

class _LiveDataChartState extends State<LiveDataChart> with SingleTickerProviderStateMixin {
  List<FlSpot> spots = [];
  List<Map<String, double>> record = [];
  StreamController<List<FlSpot>> dataStream = StreamController.broadcast();
  int dataIndex = 0;
  int maxDataPoints = 150; // Max points on the graph at any time
  double maxX = 0;

  AnimationController? _animationController;
  Timer? _dataFeedTimer;
  bool isRecording = false;
  bool _isDataFeedRunning = false;
  int recordCounter = 0;

  String ipAddress = '192.168.138.183'; //ip@ de la ES32
  String port = '80'; // port de la ES32

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 20),
    );
    //  Lancer automatiquement la réception de données à l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
    toggleDataFeed();
    startRecording(); // ← Optionnel
});
  }
  int heartRate = 0;
List<DateTime> peakTimestamps = [];

void detectPeakAndCalculateBPM(double value) {
  // Seulement si le signal dépasse un seuil (valeur approximative à ajuster)
  if (value > 800) {
    final now = DateTime.now();

    if (peakTimestamps.isEmpty || now.difference(peakTimestamps.last).inMilliseconds > 300) {
      peakTimestamps.add(now);
      if (peakTimestamps.length >= 2) {
        final intervalMs = now.difference(peakTimestamps[peakTimestamps.length - 2]).inMilliseconds;
        if (intervalMs > 0) {
          final bpm = 60000 / intervalMs;
          setState(() {
            heartRate = bpm.round();
          });
        }
      }
    }
  }
}


  void toggleDataFeed() async {
    if (_isDataFeedRunning) {
      await sendCommandToArduino("stop");
      _dataFeedTimer?.cancel();
    } else {
      await sendCommandToArduino("start");
      _dataFeedTimer = Timer.periodic(Duration(milliseconds: 200), (timer) async {
        double newY = await fetchDataFromArduino();
        updateChartData(newY);
        _animationController?.forward(from: 0);
      });
    }

    setState(() {
      _isDataFeedRunning = !_isDataFeedRunning;
    });
  }

  Future<void> sendCommandToArduino(String command) async {
    try {
      //final response = await http.get(Uri.parse('https://ton-api.com/ecg-data'));
      final response = await http.get(Uri.parse('http://$ipAddress:$port/$command'));
      if (response.statusCode == 200) {
        print('$command command sent successfully.');
      } else {
        throw Exception('Failed to send $command command');
      }
    } catch (e) {
      
      print('Error sending $command command: $e');
    }
  }

  Future<double> fetchDataFromArduino() async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddress:$port/'));
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return jsonData['milliVolt'].toDouble();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      return 0.0;
    }
  }

  void updateChartData(double newY) {
    if (spots.length >= maxDataPoints) {
      spots.clear();
    }
    final newSpot = FlSpot(spots.length.toDouble(), newY);
    spots.add(newSpot);
    maxX = newSpot.x;
    dataStream.add(List<FlSpot>.from(spots));

    if (isRecording) {
      record.add({'x': newSpot.x, 'y': newSpot.y});
    }
    detectPeakAndCalculateBPM(newY);
  }

  void startRecording() {
    setState(() {
      isRecording = true;
      record.clear();
    });
  }

  void stopRecording(BuildContext context) {
    setState(() {
      isRecording = false;
    });
    saveRecordToDatabase(context);
  }

  Future<void> saveRecordToDatabase(BuildContext context) async {
  final userEmail = Provider.of<UserProvider>(context, listen: false).email;
  if (userEmail.isEmpty) return;

  var recordData = {
    'email': userEmail,
    'data': record,
    'timestamp': DateTime.now().toIso8601String(),
  };

  try {
    final response = await http.post(
      Uri.parse('http://<TON_BACKEND>:3000/save-record'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(recordData),
    );

    if (response.statusCode == 200) {
      print('Record saved to PostgreSQL.');
    } else {
      print('Failed to save record. Status: ${response.statusCode}');
    }
  } catch (e) {
    print('Error saving to PostgreSQL: $e');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cardio Track'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 0,
            child: Container(),
          ),
          Expanded(
            flex: 7,
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController!,
                builder: (context, child) {
                  return StreamBuilder<List<FlSpot>>(
                    stream: dataStream.stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Color.fromARGB(255, 189, 184, 184), width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(8),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              drawVerticalLine: true,
                              horizontalInterval: 100,
                              verticalInterval: 10,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: Color.fromARGB(255, 177, 175, 175),
                                  strokeWidth: 1,
                                );
                              },
                              getDrawingVerticalLine: (value) {
                                return FlLine(
                                  color: Color.fromARGB(255, 177, 175, 175),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(
                              show: false,
                            ),
                            minX: 0,
                            maxX: maxDataPoints.toDouble(),
                            minY: -200,
                            maxY: 3000,
                            lineBarsData: [
                              LineChartBarData(
                                spots: snapshot.data!,
                                isCurved: true,
                                dotData: FlDotData(show: false),
                                color: Theme.of(context).brightness == Brightness.dark
                                ? const Color.fromARGB(255, 255, 255, 255)  // couleur claire pour dark mode
                                : Color.fromARGB(255, 54, 55, 56), // couleur foncée pour light mode
                                barWidth: 1.5,
                              ),
                            ],
                            lineTouchData: LineTouchData(enabled: false),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Padding(
  padding: const EdgeInsets.symmetric(vertical: 10),
  child: Text(
    'Rythme cardiaque : $heartRate BPM',
    style: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.red,
    ),
  ),
),
          if (isRecording)
            Text(
              'Recording...',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: toggleDataFeed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: _isDataFeedRunning ? Colors.red : Colors.green, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isDataFeedRunning ? 'Stop' : 'Start',
                      style: TextStyle(
                        color: _isDataFeedRunning ? Colors.red : Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isRecording) {
                        stopRecording(context);
                      } else {
                        startRecording();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: isRecording ? Colors.red : Colors.green, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isRecording ? 'Stop Recording' : 'Record',
                      style: TextStyle(
                        color: isRecording ? Colors.red : Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _dataFeedTimer?.cancel();
    dataStream.close();
    super.dispose();
  }
}
