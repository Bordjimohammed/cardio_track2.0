// Import des dépendances nécessaires
import 'package:flutter/material.dart';
import '../pages/first_page.dart';
import '../pages/dashboard.dart';
import '../pages/logout_page.dart';
import '../pages/medicaladvice_page.dart';
import '../pages/custom_page.dart'; // Custom painter
import '../pages/ecg.dart'; // ECG Page
import 'package:flutter/material.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const FirstPage(),
    const DashboardPage(),
    const LiveDataChart(), // Page ECG
    MedicalAdvicePage(), // Page des conseils médicaux
    const LogoutPage(), // Page de déconnexion
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Affiche la page correspondante
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Change la page affichée
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_outlined),
            label: 'ECG',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Conseils médicaux',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Decconnecter',
          ),
        ],
      ),
    );
  }
}
