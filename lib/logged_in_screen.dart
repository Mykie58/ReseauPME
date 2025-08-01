import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

bool hasMeetings = false;


class LoggedInScreen extends StatefulWidget {
  @override
  _LoggedInScreenState createState() => _LoggedInScreenState();
}

class _LoggedInScreenState extends State<LoggedInScreen> {
  String prenom = '';
  String nom = '';
  String company = '';
  bool hasMeetings = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _checkUserMeetings();
  }

Future<void> _loadUserInfo() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    // Vérifie que le document existe et contient bien des infos utiles
    if (!doc.exists || doc.data() == null || !doc.data()!.containsKey('prenom')) {
      // Document inexistant ou incomplet → déconnexion et retour au login
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    // Chargement des données dans l’état local
    setState(() {
      prenom = doc['prenom'] ?? '';
      nom = doc['nom'] ?? '';
      company = doc['company'] ?? '';
    });
  }
}


  Future<void> _checkUserMeetings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final createdSnap = await FirebaseFirestore.instance
        .collection('meetings')
        .where('createur_id', isEqualTo: uid)
        .limit(1)
        .get();

    if (createdSnap.docs.isNotEmpty) {
      setState(() => hasMeetings = true);
      return;
    }

    final participantSnap = await FirebaseFirestore.instance
        .collection('meetings')
        .where('participants', arrayContains: uid)
        .limit(1)
        .get();

    setState(() => hasMeetings = participantSnap.docs.isNotEmpty);
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '$prenom $nom';

    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenue $fullName'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('👋 Bonjour $fullName !', style: TextStyle(fontSize: 24)),
              SizedBox(height: 12),
              Text('Société : $company', style: TextStyle(fontSize: 18, color: Colors.grey[700])),
SizedBox(height: 24),
ElevatedButton.icon(
  onPressed: () async {
    final result = await Navigator.pushNamed(context, '/meetingsNearby');
    if (result == true) _checkUserMeetings(); // 🔁 mise à jour état
  }, // ← celle-ci manquait
  icon: Icon(Icons.location_on_outlined),
  label: Text('Réunions autour de moi'),
  style: ElevatedButton.styleFrom(
    minimumSize: Size(double.infinity, 48),
    textStyle: TextStyle(fontSize: 16),
  ),
),
SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
  final result = await Navigator.pushNamed(context, '/createMeeting');
  if (result == true) _checkUserMeetings(); // ✅ mise à jour immédiate
},
                icon: Icon(Icons.add_circle_outline),
                label: Text("Créer un événement"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/editProfile'),
                icon: Icon(Icons.edit),
                label: Text('Modifier mon profil'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
              SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/myMeetings'),
                  icon: Icon(Icons.event_available),
                  label: Text('Mes réunions'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _logout,
                icon: Icon(Icons.logout),
                label: Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

