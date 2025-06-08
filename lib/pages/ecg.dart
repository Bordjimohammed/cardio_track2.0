import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class LiveDataChart extends StatefulWidget {
  const LiveDataChart({super.key});

  @override
  _LiveDataChartState createState() => _LiveDataChartState();
}

class _LiveDataChartState extends State<LiveDataChart> with SingleTickerProviderStateMixin {
  List<FlSpot> spots = [];
  List<Map<String, double>> record = [];
  StreamController<List<FlSpot>> dataStream = StreamController.broadcast();
  AnimationController? _animationController;
  Timer? _dataFeedTimer;

  int heartRate = 0;
  List<DateTime> peakTimestamps = [];

  int maxDataPoints = 150;
  double maxX = 0;
  bool isRecording = false;
  bool _isDataFeedRunning = false;

  final storage = const FlutterSecureStorage();
  final String ipAddress = '192.168.2.183'; // ESP32 IP
  final String port = '80';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 0));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      toggleDataFeed();
      startRecording();
    });
  }

  int calculateBPMFromSpots(List<FlSpot> spots, {int minIntervalMs = 300, double sensitivity = 0.7, double samplingRate = 50}) {
  if (spots.length < 2) return 0;

  double maxY = spots.map((s) => s.y).reduce(max);
  double threshold = maxY * sensitivity;
  List<double> rPeaksX = [];
  double lastPeakX = -10000;

  for (int i = 1; i < spots.length - 1; i++) {
    double prev = spots[i - 1].y;
    double curr = spots[i].y;
    double next = spots[i + 1].y;

    if (curr > threshold && curr > prev && curr > next) {
      if (((spots[i].x - lastPeakX) / samplingRate * 1000) > minIntervalMs) {
        rPeaksX.add(spots[i].x);
        lastPeakX = spots[i].x;
      }
    }
  }

  if (rPeaksX.length < 2) return 0;

  List<double> intervals = [];
  for (int i = 1; i < rPeaksX.length; i++) {
    intervals.add((rPeaksX[i] - rPeaksX[i - 1]) / samplingRate);
  }
  double meanInterval = intervals.reduce((a, b) => a + b) / intervals.length;
  return meanInterval > 0 ? (60 / meanInterval).round() : 0;
  

  
}


Future<Position?> getCurrentPosition() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return null;
  }
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return null;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    return null;
  }
  return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
}

Future<void> sendAlertSMS(String telProche, String telDocteur, String message) async {
  final position = await getCurrentPosition();
String locationText = '';
if (position != null) {
  locationText = '\nLocalisation: https://maps.google.com/?q=${position.latitude},${position.longitude}';
} else {
  locationText = '\nLocalisation: non disponible';
}
final smsUri = Uri.parse('sms:$telProche,$telDocteur?body=${Uri.encodeComponent(message + locationText)}');
if (await canLaunchUrl(smsUri)) {
  await launchUrl(smsUri);
} else {
  print("Impossible d'ouvrir l'application SMS.");
}
if (heartRate <= 60) {
  final alertMessage = "Alerte CardioTrack : BPM bas détecté ($heartRate bpm). Merci de vérifier l'état du patient.";
  sendAlertSMS(telProche, telDocteur, alertMessage);
}
}

  void toggleDataFeed() async {
    if (_isDataFeedRunning) {
      await sendCommandToArduino("stop");
      _dataFeedTimer?.cancel();
    } else {
      await sendCommandToArduino("start");
      _dataFeedTimer = Timer.periodic(Duration(milliseconds: 20), (timer) async {
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
      final response = await http.get(Uri.parse('http://$ipAddress:$port/$command'));
      if (response.statusCode != 200) throw Exception('Failed to send $command');
    } catch (e) {
      print('Error sending $command: $e');
    }
  }

  Future<double> fetchDataFromArduino() async {
    try {
      final response = await http.get(Uri.parse('http://$ipAddress:$port/'));
      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return jsonData['milliVolt'].toDouble();
      }
    } catch (_) {}
    return 0.0;
  }

  void updateChartData(double newY) {
    if (spots.length >= maxDataPoints) spots.clear();
    final newSpot = FlSpot(spots.length.toDouble(), newY);
    spots.add(newSpot);
    maxX = newSpot.x;
    dataStream.add(List<FlSpot>.from(spots));
    if (isRecording) record.add({'x': newSpot.x, 'y': newSpot.y});
  }

  void startRecording() {
    setState(() {
      isRecording = true;
      record.clear();
    });
  }

  void stopRecording(BuildContext context) {
    setState(() => isRecording = false);
    saveRecordToDatabase(context);
  }

  Future<void> saveRecordToDatabase(BuildContext context) async {
    var recordData = {
      'signal': record,
      'bpm': heartRate,
    };

    String? token = await storage.read(key: 'access_token');
    try {
      final response = await http.post(
        Uri.parse('https://cardiotrack-server.onrender.com/data'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer $token',
        },
        body: json.encode(recordData),
      );

      if (response.statusCode == 200) {
        print('Record saved.');
      } else {
        print('Save failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cardio Track', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.red[400],
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 7,
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController!,
                builder: (_, __) {
                  return StreamBuilder<List<FlSpot>>(
                    stream: dataStream.stream,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.all(8),
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: true),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: maxDataPoints.toDouble(),
                            minY: -100,
                            maxY: 3500,
                            lineBarsData: [
                              LineChartBarData(
                                spots: snapshot.data!,
                                isCurved: true,
                                dotData: FlDotData(show: false),
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                                barWidth: 1.5,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 10),
          Text('Rythme cardiaque : $heartRate BPM',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
          if (isRecording)
            Text('Recording...', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: toggleDataFeed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: _isDataFeedRunning ? Colors.red : Colors.green, width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    _dataFeedTimer?.cancel();
    _animationController?.dispose();
    dataStream.close();
    super.dispose();
  }
}
