import 'package:flutter/material.dart';

class Screen2 extends StatelessWidget {
  const Screen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          "lib/images/intro2.png",
          width:190,
          height:190,
          fit: BoxFit.cover,),
        const SizedBox(height: 0),
        const SizedBox(height: 80),
        const Text(
          "Graphiques ECG en direct",
          style: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
              "Visualisez vos signaux ECG en direct grâce à une interface simple et intuitive, connectée à votre capteur via Wi-Fi" ,       
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