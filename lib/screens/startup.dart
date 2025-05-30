import 'package:Cardio_Track/intro_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:Cardio_Track/navbar/navbar.dart';

final storage = const FlutterSecureStorage();

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});
  @override
  State<StatefulWidget> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();
    onstartup(context);
  }

  void onstartup(BuildContext context) async {
    // Affiche un écran d'introduction
    String? token = await storage.read(key: 'refresh_token');

    final response = await http.post(
      Uri.parse("http://192.168.43.40:5000/refresh"),
      headers: {
        'Authorization': 'Bearer $token',
        "Content-Type": "application/json"
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: 'access_token', value: data['access_token']);
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => NavBar()));
    } else {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => IntroScreens()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => onstartup(context),
          child: const Text('Démarrer'),
        ),
      ),
    );
  }
}
