import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantsScreen extends StatelessWidget {
  final List<String> participantIds;

  ParticipantsScreen({required this.participantIds});

  Future<List<Map<String, dynamic>>> _fetchParticipants() async {
    final usersRef = FirebaseFirestore.instance.collection('users');
    final result = <Map<String, dynamic>>[];

    for (final uid in participantIds) {
      final doc = await usersRef.doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          result.add({
            'prenom': data['prenom'] ?? '',
            'nom': data['nom'] ?? '',
            'company': data['company'] ?? '',
          });
        }
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Participants")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchParticipants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }

          final participants = snapshot.data ?? [];

          if (participants.isEmpty) {
            return Center(child: Text("Aucun participant"));
          }

          return ListView.builder(
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final p = participants[index];
              return ListTile(
                leading: Icon(Icons.person),
                title: Text("${p['prenom']} ${p['nom']}"),
                subtitle: Text(p['company']),
              );
            },
          );
        },
      ),
    );
  }
}

