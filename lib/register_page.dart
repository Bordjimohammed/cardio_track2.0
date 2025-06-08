import 'package:Cardio_Track/login_page.dart';
import 'package:Cardio_Track/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:Cardio_Track/components/my_button.dart';
import 'package:Cardio_Track/components/my_textfield.dart';
import 'package:Cardio_Track/components/square_tile.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Pour le stockage sécurisé
import 'package:Cardio_Track/navbar/navbar.dart';
import 'dart:convert';
import 'package:provider/provider.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
/*
  void registerUser() {
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❗ Veuillez remplir tous les champs")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❗ Les mots de passe ne correspondent pas")),
      );
      return;
    }

    // Simule une inscription réussie
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Compte créé avec succès")),
    );

    // Revenir à la page de connexion
    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => NavBar()),
                      );
  }
*/
Future<void> registerUser() async {
  final email = emailController.text.trim();
  final name = nameController.text.trim();
  final password = passwordController.text.trim();
  final confirmPassword = confirmPasswordController.text.trim();

  // Vérification du format email
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  if (!emailRegex.hasMatch(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(" Email invalide. Format attendu : x.x@x.com")),
    );
    return;
  }

  if (email.isEmpty || name.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(" Veuillez remplir tous les champs")),
    );
    return;
  }
  if (password != confirmPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(" Les mots de passe ne correspondent pas")),
    );
    return;
  }

  final url = Uri.parse("https://cardiotrack-server.onrender.com/sign-in");
  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "email": email,
      "name": name,
      "password": password,
    }),
  );
  if (response.statusCode == 201) {
    final data = jsonDecode(response.body);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'])),
    );
    final url2 = Uri.parse("https://cardiotrack-server.onrender.com/log-in");
    final response2 = await http.post(
      url2,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
    if (response2.statusCode == 200) {
      final data2 = jsonDecode(response2.body);
      final storage = FlutterSecureStorage();
      await storage.write(
          key: 'refresh_token', value: data2['refresh_token']);
      await storage.write(key: 'access_token', value: data2['access_token']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data2['message'])),
      );
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => NavBar()));
    } else {
      final data = jsonDecode(response2.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['error'])),
      );
    }
  } else {
    final data = jsonDecode(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['error'])),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Image.asset('lib/images/logo.png', height: 175, width: 200),
                const SizedBox(height: 20),
                Text(
                  'Créez votre compte',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 25),
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                MyTextField(
                  controller: nameController,
                  hintText: 'Nom',
                  obscureText: false,
                ),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Mot de passe',
                  obscureText: true,
                ),
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirmez le mot de passe',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                MyButton(onTap: registerUser),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SquareTile(imagePath: 'lib/images/google.png'),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Déjà inscrit ?",
                        style: TextStyle(color: Colors.grey[700])),
                    TextButton(
                      child: const Text(
                        "Se connecter",
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                      Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => LoginPage()),
                      );                      },
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
