// Importation des composants nécessaires

import 'package:Cardio_Track/intro_screen.dart';
import 'package:Cardio_Track/login_page.dart';
import 'package:Cardio_Track/navbar/navbar.dart';
import 'package:Cardio_Track/root_page.dart';
import 'package:Cardio_Track/spalsh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/theme_provider.dart';
import '../providers/user_provider.dart';


void main()async {
  WidgetsFlutterBinding.ensureInitialized(); // Nécessaire pour attendre des appels asynchrones
  runApp(
    
    MultiProvider(
      providers: [
        
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HeartRateProvider()),
        ChangeNotifierProvider(create: (_) => EcgProvider()),


// 💡 ajoute ce provider
      ],
      child: MyApp(),
    ),
  );
}

// Classe principale de l'application
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Constructeur avec clé optionnelle

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const RootPage(),
      //home:  IntroScreens (),
      themeMode: Provider.of<ThemeProvider>(context).themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    
    );
  }
  
}
