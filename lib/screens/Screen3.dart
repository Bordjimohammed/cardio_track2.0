import 'package:flutter/material.dart';

class Screen3 extends StatelessWidget {
  const Screen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          "lib/images/intro2.png",
          width:200,
          height:250,
          fit: BoxFit.cover,),
        const SizedBox(height: 0),
        const SizedBox(height: 80),
        const Text(
          " Analyse et suivi personnalisé",
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
            "Visualisez, enregistrez et analysez vos battements cardiaques avec précision pour un meilleur suivi médical.",
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