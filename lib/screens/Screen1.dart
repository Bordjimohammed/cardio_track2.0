import 'package:flutter/material.dart';

class Screen1 extends StatelessWidget {
  const Screen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset("lib/images/logo.png",
            width:500,
          height:250,
          fit: BoxFit.cover,),
        const SizedBox(height: 60),
        const SizedBox(height: 0),
        const Text(
          "Bienvenue sur CardioTrack",
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height:0),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Surveillez votre activité cardiaque en temps réel et prenez soin de votre santé où que vous soyez.",
            style: TextStyle(
              color: Colors.black.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}