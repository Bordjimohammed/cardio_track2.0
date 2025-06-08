import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserProvider with ChangeNotifier {
  String _userName = '';
  String _email = '';
  String _password = '';
  String token = '';
  String telProche = '';
  String telDocteur = '';

  String get userName => _userName;
  String get email => _email;
  String get password => _password;

  void setPassword(String newPassword) {
  _password = newPassword;
  notifyListeners();
}

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    notifyListeners();
  }

  void clearUser() {
    _userName = '';
    _email = '';
    _password = '';
    notifyListeners();
  }
  void setTelProche(String value) {
  telProche = value;
  notifyListeners();
}
void setTelDocteur(String value) {
  telDocteur = value;
  notifyListeners();
}

}
class HeartRateProvider with ChangeNotifier {
  int _heartRate = 0;

  int get heartRate => _heartRate;

  void updateHeartRate(int value) {
    _heartRate = value;
    notifyListeners();
  }

  void setHeartRate(int heartRate) {}


  }
class EcgProvider with ChangeNotifier {
  bool _isRunning = false;
  List<FlSpot> _data = [];

  bool get isRunning => _isRunning;

  List<FlSpot> get data => _data;

  void start() {
    _isRunning = true;
    notifyListeners();
    _fetchData();
  }

  void stop() {
    _isRunning = false;
    notifyListeners();
  }

  void _fetchData() async {
    double x = _data.isNotEmpty ? _data.last.x + 0.1 : 0.0;
    while (_isRunning) {
      final y = await _getEcgSample(); // ton appel HTTP vers ESP32
      _data.add(FlSpot(x, y));
      if (_data.length > 2000) {
        _data.removeAt(0); // pour ne pas avoir trop de points
      }
      x += 0.1;
      notifyListeners();
      await Future.delayed(Duration(milliseconds: 50));
    }
  }

  Future<double> _getEcgSample() async {
    // Remplace cette partie avec ton code HTTP
    final response = await http.get(Uri.parse('http://192.168.x.x/data'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['value'].toDouble();
    } else {
      return 0.0;
    }
  }

}
