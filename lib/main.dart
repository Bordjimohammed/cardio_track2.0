// Importation des composants nécessaires
import 'package:Cardio_Track/navbar/navbar.dart';
import 'package:Cardio_Track/pages/dashboard.dart';
import 'package:Cardio_Track/pages/first_page.dart';
import 'package:Cardio_Track/screens/startup.dart';
import 'package:flutter/material.dart'; // Import du SDK Flutter de base
import 'package:Cardio_Track/pages/medicaladvice_page.dart';
import 'intro_screen.dart';
import 'package:provider/provider.dart'; // Pour la gestion d'état
import '../pages/ecg.dart';
import '../pages/logout_page.dart';
import '../login_page.dart';
import 'pages/theme_provider.dart'; // Gestionnaire de thème
import '../providers/user_provider.dart'; // Gestionnaire des données utilisateur


// Fonction principale qui lance l'application
void main() {
  runApp(
    // MultiProvider permet d'utiliser plusieurs fournisseurs d'état
    MultiProvider(
      providers: [
        // Provider pour les données utilisateur
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HeartRateProvider()),

// 💡 ajoute ce provider
      ],
      child: MyApp(), // Notre application principale
    ),
  );
}

// Classe principale de l'application
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Constructeur avec clé optionnelle

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Désactive la bannière debug
      home:  NavBar(), // Premier écran affiché (écrans d'introduction)
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    
    );
  }
  
}
