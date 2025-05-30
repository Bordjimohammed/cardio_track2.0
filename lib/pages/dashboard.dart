import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  final List<Map<String, String>> historique = const [
    {
      "date": "22 avril 2025",
      "rythme": "72 bpm",
      "status": "Normal"
    },
    {
      "date": "20 avril 2025",
      "rythme": "88 bpm",
      "status": "Tachycardie"
    },
    {
      "date": "18 avril 2025",
      "rythme": "65 bpm",
      "status": "Normal"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Historique ECG'),
        centerTitle: true,
        backgroundColor: Colors.red[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: historique.isEmpty
            ? Center(
                child: Text("Aucun test enregistré pour le moment.",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600])),
              )
            : ListView.builder(
                itemCount: historique.length,
                itemBuilder: (context, index) {
                  final test = historique[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.monitor_heart,
                          color: Colors.red[300], size: 30),
                      title: Text("Test du ${test['date']}"),
                      subtitle: Text("Rythme : ${test['rythme']} • ${test['status']}"),
                      trailing: IconButton(
                        icon: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                        onPressed: () {
                          // Action : voir les détails ou supprimer
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("👉 Détails du test à venir")),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              
      ),
    );
  }
}
