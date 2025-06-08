import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../pages/theme_provider.dart';
import '../login_page.dart';
import 'package:geolocator/geolocator.dart';


class LogoutPage extends StatefulWidget {
  const LogoutPage({super.key});

  @override
  State<LogoutPage> createState() => _LogoutPageState();
}

class _LogoutPageState extends State<LogoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _procheNomController = TextEditingController();
  final _procheTelController = TextEditingController();
  final _docteurNomController = TextEditingController();
  final _docteurTelController = TextEditingController();
      late String userEmail;

  Future<void> _saveLocalContacts() async {
  final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${userEmail}_proche_nom', _procheNomController.text.trim());
    await prefs.setString('${userEmail}_proche_tel', _procheTelController.text.trim());
    await prefs.setString('${userEmail}_docteur_nom', _docteurNomController.text.trim());
    await prefs.setString('${userEmail}_docteur_tel', _docteurTelController.text.trim());
  }
  Future<void> _loadLocalContacts() async {
    final prefs = await SharedPreferences.getInstance();
    _procheNomController.text = prefs.getString('${userEmail}_proche_nom') ?? '';
    _procheTelController.text = prefs.getString('${userEmail}_proche_tel') ?? '';
    _docteurNomController.text = prefs.getString('${userEmail}_docteur_nom') ?? '';
    _docteurTelController.text = prefs.getString('${userEmail}_docteur_tel') ?? '';
  }
  @override
  Widget build(BuildContext context) {
      String? email;

    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.red[400],
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... Carte de contact
              Card(
                elevation: 2,
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(userProvider.userName),
                  subtitle: const Text('Voir les détails'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showUserProfile(context, userProvider),
                ),
              ),

              // ... Mode sombre
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mode sombre',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Switch(
                            value: themeProvider.isDarkMode,
                            onChanged: (value) => themeProvider.toggleTheme(value),
                            activeColor: Colors.red,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              //  Nouvelle section : Coordonnées proches/docteur
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Coordonnées d'urgence",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        // Proche
                        const Text("Nom du proche"),
                        TextFormField(
                          controller: _procheNomController,
                          decoration: const InputDecoration(
                            hintText: "Ex: Maman",
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Veuillez entrer un nom' : null,
                        ),
                        const SizedBox(height: 10),
                        const Text("Téléphone du proche"),
                        TextFormField(
                          controller: _procheTelController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: "Ex: 0555 55 55 55",
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Veuillez entrer un numéro' : null,
                        ),
                        const SizedBox(height: 20),

                        // Docteur
                        const Text("Nom du docteur"),
                        TextFormField(
                          controller: _docteurNomController,
                          decoration: const InputDecoration(
                            hintText: "Ex: Dr. Rabah ",
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Veuillez entrer un nom' : null,
                        ),
                        const SizedBox(height: 10),
                        const Text("Téléphone du docteur"),
                        TextFormField(
                          controller: _docteurTelController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: "Ex: 0666 66 66 66",
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Veuillez entrer un numéro' : null,
                        ),

                        const SizedBox(height: 20),

                        // Bouton d'enregistrement
                        Center(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Enregistrer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final nomProche = _procheNomController.text.trim();
                                final telProche = _procheTelController.text.trim();
                                final nomDoc = _docteurNomController.text.trim();
                                final telDoc = _docteurTelController.text.trim();
                                await _saveLocalContacts();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Coordonnées enregistrées !")),
                                );
                                //  À remplacer plus tard par une sauvegarde dans base de données
                                print('Proche: $nomProche ($telProche)');
                                print('Docteur: $nomDoc ($telDoc)');

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Coordonnées enregistrées !")),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Bouton de déconnexion
              ElevatedButton.icon(
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Se déconnecter', style: TextStyle(fontSize: 16)),
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
      ),
    );
  }

  // ... Garde tes autres méthodes comme _showUserProfile et _showLogoutConfirmation ici
Future<void> _enregistrerCoordonnees() async {
  final response = await http.post(
    Uri.parse('https://cardiotrack-server.onrender.com/save_contact'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "user_id": "12345", // Tu peux récupérer depuis ton Provider ou autre
      "proche_nom": _procheNomController.text.trim(),
      "proche_tel": _procheTelController.text.trim(),
      "docteur_nom": _docteurNomController.text.trim(),
      "docteur_tel": _docteurTelController.text.trim(),
    }),
  );

  if (response.statusCode == 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Coordonnées enregistrées sur le serveur.")),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Erreur lors de l'enregistrement.")),
    );
  }
}
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

void _showUserProfile(BuildContext context, UserProvider userProvider) {
  
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();


  showModalBottomSheet(
    
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      bool obscureAncien = true;
      bool obscureNouveau = true;
      bool obscureConfirmation = true;
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Profil utilisateur',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(userProvider.userName, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.email, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(userProvider.email, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text('Changer le mot de passe', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // Ancien mot de passe
                  TextField(
                    controller: oldPasswordController,
                    obscureText: obscureAncien,
                    decoration: InputDecoration(
                      labelText: 'Ancien mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureAncien ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureAncien = !obscureAncien),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Nouveau mot de passe
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNouveau,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNouveau ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureNouveau = !obscureNouveau),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Confirmation
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmation,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le nouveau mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirmation ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => obscureConfirmation = !obscureConfirmation),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bouton confirmer
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        final ancien = oldPasswordController.text.trim();
                        final nouveau = newPasswordController.text.trim();
                        final confirmation = confirmPasswordController.text.trim();

                        if (ancien.isEmpty || nouveau.isEmpty || confirmation.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez remplir tous les champs')),
                          );
                          return;
                        }

                        if (nouveau.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères')),
                          );
                          return;
                        }

                        if (ancien != userProvider.password) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Ancien mot de passe incorrect')),
                          );
                          return;
                        }
                        if (nouveau != confirmation) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
                          );
                          return;
                        }
                        final response = await http.post(
                        Uri.parse('https://cardiotrack-server.onrender.com/change_password'),
                        headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer ${userProvider.token}',
                        },
                        body: jsonEncode({
                        'password': ancien,
                        'newpass': nouveau,
                        }),
                        );

                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Mot de passe modifié avec succès')),
                            );
                          } else {
                            final error = jsonDecode(response.body);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error['error'] ?? 'Erreur inconnue')),
                            );
                          }

                        // Simuler une mise à jour
                        print('Mot de passe mis à jour: $nouveau');
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mot de passe changé avec succès')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirmer'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
@override
void initState() {
  super.initState();
  // Now context is available, so we can initialize userEmail
  userEmail = Provider.of<UserProvider>(context, listen: false).email;
  _loadLocalContacts();
}
}
