import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MyMeetingsScreen extends StatefulWidget {
  @override
  _MyMeetingsScreenState createState() => _MyMeetingsScreenState();
}

class _MyMeetingsScreenState extends State<MyMeetingsScreen> {
  List<DocumentSnapshot> _meetings = [];
  bool _loading = true;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadMeetings();
  }

Future<void> _loadMeetings() async {
  if (_uid == null) return;

  setState(() => _loading = true);

  try {
    final meetingCol = FirebaseFirestore.instance.collection('meetings');

    // 1) Réunions où on est créateur
    final creatorSnap = await meetingCol
      .where('createur_id', isEqualTo: _uid)
      .get();

    // 2) Réunions où on est participant
    final participantSnap = await meetingCol
      .where('participants', arrayContains: _uid)
      .get();

    // 3) Filtrer les doublons (priorité aux créateurs)
    final creatorDocs = creatorSnap.docs;
    final creatorIds = creatorDocs.map((doc) => doc.id).toSet();

    final filteredParticipantDocs = participantSnap.docs
      .where((doc) => !creatorIds.contains(doc.id))
      .toList();

    // 4) Concaténer
    final allDocs = [
      ...creatorDocs,
      ...filteredParticipantDocs,
    ];

    setState(() {
      _meetings = allDocs;
      _loading  = false;
    });
  } catch (e) {
    print("Erreur chargement réunions : $e");
    setState(() {
      _meetings = [];
      _loading  = false;
    });
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Mes réunions")),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _meetings.isEmpty
              ? Center(child: Text("Aucune réunion trouvée"))
              : ListView.builder(
                  itemCount: _meetings.length,
                  itemBuilder: (ctx, i) {
                    final meeting = _meetings[i];
                    final title = meeting['description'] ?? '';
                    final address = meeting['address'] ?? meeting['address'] ?? '';
                    final type = meeting['type'] ?? '';
                    final ts = meeting['scheduledAt'] is Timestamp
                        ? (meeting['scheduledAt'] as Timestamp).toDate()
                        : null;

                    final isCreator = meeting['createur_id'] == _uid;

                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text("$type · $address${ts != null ? "\n" + DateFormat('dd/MM HH:mm').format(ts) : ""}"),
                        trailing: isCreator
                            ? IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/editMeeting',
                                  arguments: meeting,
                                ),
                                tooltip: "Modifier",
                              )
                            : Icon(Icons.chevron_right),
                        onTap: () {
                          if (!isCreator) {
                            Navigator.pushNamed(
                              context,
                              '/meetingDetails',
                               arguments: meeting.id,
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
