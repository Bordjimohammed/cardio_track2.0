import 'package:Cardio_Track/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:Cardio_Track/components/my_button.dart';
import 'package:Cardio_Track/components/my_textfield.dart';
import 'package:Cardio_Track/components/square_tile.dart';
import 'package:Cardio_Track/navbar/navbar.dart';
import 'package:Cardio_Track/register_page.dart';
import 'dart:convert';
import 'package:Cardio_Track/pages/reset_password_page.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  final nameController= TextEditingController();


  // Version complète avec appel API (actuellement commentée)

  Future<void> Login() async {
    final url = Uri.parse("https://cardiotrack-server.onrender.com/log-in");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": emailController.text.trim(),
        "password": passwordController.text.trim(),
        "username": nameController.text.trim(),
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final storage = FlutterSecureStorage();
      await storage.write(key: 'refresh_token', value: data['refresh_token']);
      await storage.write(key: 'access_token', value: data['access_token']);


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),
      );

      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => NavBar()));
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['error'])),
      );
    }
  }

Future<void> googleLogin() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      return;
    }
    final email = googleUser.email;
    final name = googleUser.displayName ?? "";

    final response = await http.post(
      Uri.parse("https://cardiotrack-server.onrender.com/google_login_flutter"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "name": name,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final storage = FlutterSecureStorage();
      await storage.write(key: 'refresh_token', value: data['refresh_token']);
      await storage.write(key: 'access_token', value: data['access_token']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Connexion Google réussie")),
      );

      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => NavBar()));
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['error'] ?? "Erreur Google")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Google login failed')),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300], // Couleur de fond gris clair
      body: SafeArea(
        child: SingleChildScrollView(
          // Permet le défilement si nécessaire
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Espacement et logo
                const SizedBox(height: 100),
                Image.asset(
                  'lib/images/logo.png',
                  height: 175,
                  width: 200,
                ),
                const SizedBox(height: 20),

                // Message de bienvenue
                Text(
                  'Bienvenue a Cardio Track !',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 25),

                // Champs de saisie
                MyTextField(
                  controller: emailController,
                  hintText: 'Email',
                  obscureText: false,
                ),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Mot de passe',
                  obscureText: true,
                ),
                const SizedBox(height: 10),

                // Lien "Mot de passe oublié"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Naviguer vers la page de réinitialisation
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ResetPasswordPage()),
                          );
                        },
                        child: Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            color: Colors.blue, // Style de lien
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                        'Ou continuer avec',
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
                  children: [
                    GestureDetector(
                      onTap: () {
                        googleLogin();
                      },
                      child: SquareTile(imagePath: 'lib/images/google.png'),
                    ),
                  ],
                ),
                // Lien d'inscription
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Vous n'avez pas de compte ?",
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
                        'Inscrire',
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