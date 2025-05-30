import 'package:Cardio_Track/login_page.dart';
import 'package:Cardio_Track/navbar/navbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:Cardio_Track/intro_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const IntroScreens()), // ou LoginPage, ou IntroScreen
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'lib/images/logo.png',
          width: 200,
        ),
      ),
    );
  }
}
