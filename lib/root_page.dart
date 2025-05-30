import 'package:Cardio_Track/intro_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:Cardio_Track/navbar/navbar.dart';
import 'package:Cardio_Track/login_page.dart';
import 'package:Cardio_Track/spalsh.dart';
import 'package:shared_preferences/shared_preferences.dart';
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  Future<String> getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final introSeen = prefs.getBool('intro_seen') ?? true;

    if (!introSeen) {
      return 'intro';
    }

    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      return 'navbar';
    } else {
      return 'login';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getInitialRoute(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SplashScreen();
        }
        switch (snapshot.data) {
          case 'intro':
            return IntroScreens(); // Ton widget d'intro
          case 'navbar':
            return NavBar();
          default:
            return LoginPage();
        }
      },
    );
  }
}