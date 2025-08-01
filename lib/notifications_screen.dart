import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<DocumentSnapshot> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('notifications')
        .where('createur_id', isEqualTo: uid)
        .where('type', isEqualTo: 'inscription_meeting')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _notifications = snap.docs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mes notifications")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text("Aucune inscription reçue pour l’instant"))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (ctx, i) {
                    final notif = _notifications[i];
                    final prenom = notif['prenom'] ?? '';
                    final nom = notif['nom'] ?? '';
                    final titre = notif['titre'] ?? '';
                    final ts = (notif['timestamp'] as Timestamp?)?.toDate();

                    return ListTile(
                      leading: Icon(Icons.person_add),
                      title: Text("$prenom $nom s’est inscrit à :"),
                      subtitle: Text(titre),
                      trailing: ts != null
                          ? Text(DateFormat('dd/MM HH:mm').format(ts),
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]))
                          : null,
                    );
                  },
                ),
    );
  }
}
