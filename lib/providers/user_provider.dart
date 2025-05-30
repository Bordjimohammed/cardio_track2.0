import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _userName = '';
  String _email = '';

  String get userName => _userName;
  String get email => _email;

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
}
