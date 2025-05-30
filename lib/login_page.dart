// Importations des packages et composants nécessaires
import 'package:Cardio_Track/pages/ecg.dart';
import 'package:Cardio_Track/pages/first_page.dart';
import 'package:Cardio_Track/pages/medicaladvice_page.dart';
import 'package:flutter/material.dart';
import 'package:Cardio_Track/components/my_button.dart';
import 'package:Cardio_Track/components/my_textfield.dart';
import 'package:Cardio_Track/components/square_tile.dart';
import 'package:Cardio_Track/navbar/navbar.dart';
import 'package:Cardio_Track/register_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Pour le stockage sécurisé

// Page d'accueil simple avec un texte centré
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Accueil", style: TextStyle(fontSize: 24)),
    );
  }
}

// Page de connexion avec gestion d'état
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Contrôleurs pour les champs de texte
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Méthode de connexion temporaire avec identifiants codés en dur
/*
  void Login() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email == 'username' && password == '1234') {
      // Affiche un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Connexion réussie")),
      );

      // Redirige vers la NavBar après connexion
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => NavBar()),
      );
    } else {
      // Affiche un message d'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Identifiants incorrects")),
      );
    }
  }
  */


  // Version complète avec appel API (actuellement commentée)



  Future<void> Login() async {
    final url = Uri.parse("http://192.168.43.40:5000/log-in");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailController.text.trim(),
        "password": passwordController.text.trim(),
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final storage=FlutterSecureStorage();
      await storage.write(key: 'refresh_token', value: data['refresh_token']);
      await storage.write(key: 'access_token', value: data['access_token']);

    //  print("✅ Token received: $token");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => NavBar()));
      // TODO: Sauvegarder le token avec shared_preferences
    } else {
      final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'])),
        );
    }
  }


  // Construction de l'interface utilisateur
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300], // Couleur de fond gris clair
      body: SafeArea(
        child: SingleChildScrollView( // Permet le défilement si nécessaire
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Espacement et logo
                const SizedBox(height: 100),
                Image.asset(
                  'lib/images/logo.png',
                  height: 250,
                  width: 250,
                ),
                const SizedBox(height: 20),
                
                // Message de bienvenue
                Text(
                  'Welcome back you\'ve been missed !',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 25),
                
                // Champs de saisie
                MyTextField(
                  controller: emailController,
                  hintText: 'Username',
                  obscureText: false,
                ),
                MyTextField(
                  controller: passwordController,
                  hintText: 'password',
                  obscureText: true,
                ),
                const SizedBox(height: 10),
                
                // Lien "Mot de passe oublié"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Forgot Password ?',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                
                // Bouton de connexion
                MyButton(
                  onTap: Login,
                ),
                const SizedBox(height: 100),
                
                // Séparateur "Ou continuer avec"
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 0.5,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Boutons de connexion sociale
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SquareTile(imagePath: 'lib/images/google.png'),
                    SizedBox(width: 25),
                    SquareTile(imagePath: 'lib/images/apple.png'),
                  ],
                ),
                
                // Lien d'inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Not a member ?',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RegisterPage()),
    );
  },
  child: const Text(
    'Register now',
    style: TextStyle(
      color: Colors.blue, fontWeight: FontWeight.bold),
  ),
)
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}