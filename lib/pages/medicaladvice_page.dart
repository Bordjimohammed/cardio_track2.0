import 'package:flutter/material.dart';

// Classe principale affichant les conseils médicaux
class MedicalAdvicePage extends StatelessWidget {
  // Liste des conseils sous forme d'objets MedicalAdvice
  final List<MedicalAdvice> conseils = [
    MedicalAdvice(
      title: "Hydratation",
      description: "Buvez au moins 2L d'eau par jour pour maintenir une bonne circulation sanguine",
      icon: Icons.local_drink,
      color: Colors.blue,
      tips: [
        "Commencez la journée avec un verre d'eau",
        "Emportez une bouteille réutilisable",
        "Limitez les boissons sucrées"
      ],
      source:" OMS - Recommandations hydratation 2023" ,
    ),
    MedicalAdvice(
      title: "Activité Physique",
      description: "30 minutes d'exercice modéré quotidien renforcent votre cœur",
      icon: Icons.directions_run,
      color: Colors.green,
      tips: [
        "Marche rapide 5 fois par semaine",
        "Piscine 2-3 fois par semaine",
        "Évitez la position assise prolongée"
      ],
    source:"Fédération Française de Cardiologie" ,

    ),
    MedicalAdvice(
      title: "Gestion du Stress",
      description: "Le stress chronique augmente la pression artérielle",
      icon: Icons.self_improvement,
      color: Colors.purple,
      tips: [
        "Pratiquez la respiration profonde",
        "Méditation 10 min/jour",
        "Limitez l'exposition aux écrans avant le coucher"
      ],
      source:"Mayo Clinic – Stress Management 2023",
    ),
    MedicalAdvice(
      title: "Alimentation",
      description: "Une alimentation équilibrée protège votre système cardiovasculaire",
      icon: Icons.restaurant,
      color: Colors.orange,
      tips: [
        "5 portions de fruits/légumes par jour",
        "Privilégiez les graisses insaturées",
        "Limitez le sel à 5g/jour"
      ],
      source:"PNNS - Programme National Nutrition Santé",

    ),
    MedicalAdvice(
      title: "Sommeil",
      description: "Un sommeil de qualité est essentiel pour la santé cardiaque",
      icon: Icons.bedtime,
      color: Colors.indigo,
      tips: [
        "7-8 heures de sommeil par nuit",
        "Couchez-vous à heure régulière",
        "Évitez les écrans 1h avant le coucher"
      ],
      source: "American Heart Association",

    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre d'app en haut avec bouton de recherche
      appBar: AppBar(
        title: const Text("Conseils Santé"),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context), // Affiche la boîte de dialogue de recherche
          ),
        ],
      ),
      // Affiche chaque conseil sous forme de carte dans une liste
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: conseils.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16), // Espace entre les cartes
        itemBuilder: (context, index) => _buildAdviceCard(conseils[index]), // Construction de la carte
      ),
    );
  }

  // Méthode pour construire chaque carte de conseil
  Widget _buildAdviceCard(MedicalAdvice advice) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Coins arrondis
      ),
      child: ExpansionTile(
        leading: Icon(advice.icon, color: advice.color), // Icône à gauche
        title: Text(
          advice.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Text('${advice.description}\n${advice.source}',
          style: TextStyle(fontSize: 12,color: Colors.grey[700]),), // Description sous le titre
        children: [
          // Détails affichés lorsqu'on ouvre la carte
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Recommandations:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Affiche chaque conseil sous forme de ligne avec flèche
                ...advice.tips.map((tip) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.arrow_right, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(tip)),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Affiche un champ de recherche dans une boîte de dialogue
  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rechercher un conseil"),
        content: TextField(
          decoration: const InputDecoration(hintText: "Ex: Hydratation, Sommeil..."),
          onChanged: (query) {
            // Implémentez la recherche ici (non implémenté dans ce code)
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () {
              // Action de recherche (pas encore codée)
              Navigator.pop(context);
            },
            child: const Text("Rechercher"),
          ),
        ],
      ),
    );
  }
}

// Classe modèle représentant un conseil médical
class MedicalAdvice { // final final = une fois initialisée, on ne peut plus la changer.
  final String title; // Titre du conseil
  final String description; // Brève description
  final IconData icon; // Icône à afficher
  final Color color; // Couleur de l’icône
  final List<String> tips;
  final String source; // Liste des recommandations détaillées

  MedicalAdvice({
    required this.title, //required : tu es obligé de fournir une valeur pour title quand tu crées un objet MedicalAdvice.
    required this.description,
    required this.icon,
    required this.color,
    required this.tips,
    required this.source,
  });
}
