import 'dart:convert';//Permet de convertir les réponses JSON de l’API (jsonDecode) en objets Dart.
import 'package:Cardio_Track/components/my_button.dart';
import 'package:Cardio_Track/login_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Gestionnaire de thème
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;//Pour envoyer des requêtes HTTP vers ton backend (ex: déconnexion via l’API).

class LogoutPage extends StatelessWidget {
  const LogoutPage({super.key});
  final storage = const FlutterSecureStorage();

  Future<void> _logout(BuildContext context) async {
    // Ici vous pourriez ajouter:
    // 1. Nettoyage des données utilisateur
    // 2. Appel API pour déconnexion serveur
    // 3. Réinitialisation du state de l'application
    String? token = await storage.read(key: 'refresh_token');

    final response = await http.post(
      Uri.parse("http://192.168.43.40:5000/log_out"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'refresh_token': token,
      },),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.delete(key: 'refresh_token');
      await storage.delete(key: 'access token');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'])),      
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage()));
    } else {
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['error'])),
      );
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false, // Supprime toute la pile de navigation
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        automaticallyImplyLeading: false, // Supprime le bouton retour
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Compte
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compte',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildAccountOption(
                      icon: Icons.person,
                      title: 'Profil',
                      onTap: () {
                        // Navigation vers le profil
                      },
                    ),
                    _buildAccountOption(
                      icon: Icons.security,
                      title: 'Sécurité',
                      onTap: () {
                        // Navigation vers la sécurité
                      },
                    ),
                    _buildAccountOption(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      onTap: () {
                        // Navigation vers les notifications
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Section Mode Sombre
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mode sombre',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Switch(
                          value: themeProvider.isDarkMode,
                          onChanged: (value) {
                            themeProvider.toggleTheme(value);
                          },
                          activeColor: Colors.red,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bouton de déconnexion
            ElevatedButton.icon(
              icon: const Icon(Icons.logout, size: 20),
              label: const Text(
                'Se déconnecter',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red[400],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _showLogoutConfirmation(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la déconnexion'),
        content: const Text(
            'Voulez-vous vraiment vous déconnecter de CardioTrack ?'),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () =>Navigator.pop( _logout(context) as BuildContext),
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context) {
    // Ici vous pourriez ajouter:
    // 1. Nettoyage des données utilisateur
    // 2. Appel API pour déconnexion serveur
    // 3. Réinitialisation du state de l'application

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false, // Supprime toute la pile de navigation
    );
  }
}
