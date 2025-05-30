import 'package:Cardio_Track/components/my_textfield.dart';
import 'package:flutter/material.dart';
class ResetPasswordPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300], // Couleur de fond gris clair
      appBar: AppBar(title: Text('Réinitialiser le mot de passe') ,backgroundColor: Colors.grey[300],), // Couleur de fond gris clair
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            MyTextField(
                  controller: emailController,
                  hintText: 'Adresse Email',
                  obscureText: false,
                ),
      SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(25),
        margin: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 214, 26, 26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            "Envoyer le lien de réinitialisation",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
        ],
        ),
      ),
    );
  }
}
