import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class MeetingDetailsScreen extends StatefulWidget {
  @override
  _MeetingDetailsScreenState createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends State<MeetingDetailsScreen> {
  String? meetingId;
  DocumentSnapshot<Map<String, dynamic>>? meeting;
  bool loading = true;
  bool isParticipating = false;
  List<String> participants = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is String) {
        meetingId = args;
        _loadMeeting(args);
      }
    });
  }

  Future<void> _loadMeeting(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('meetings')
        .doc(id)
        .get();
    final data = doc.data()!;
    final parts = List<String>.from(data['participants'] ?? []);
    final uid = FirebaseAuth.instance.currentUser?.uid;

    setState(() {
      meeting = doc;
      participants = parts;
      isParticipating = uid != null && parts.contains(uid);
      loading = false;
    });
  }

  Future<void> _toggleParticipation() async {
    if (meetingId == null || meeting == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final ref =
        FirebaseFirestore.instance.collection('meetings').doc(meetingId);

    if (isParticipating) {
      await ref.update({
        'participants': FieldValue.arrayRemove([uid])
      });
      participants.remove(uid);
    } else {
      await ref.update({
        'participants': FieldValue.arrayUnion([uid])
      });
      participants.add(uid);

      final creatorId = meeting!.data()!['createur_id'] as String?;
      if (creatorId != null && creatorId != uid) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'inscription_meeting',
          'meetingId': meetingId,
          'titre': meeting!.data()!['description'],
          'userId': uid,
          'prenom': userDoc.data()?['prenom'] ?? '',
          'nom': userDoc.data()?['nom'] ?? '',
          'createur_id': creatorId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }

    setState(() {
      isParticipating = !isParticipating;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isParticipating
              ? "Tu participes à cette réunion 🎉"
              : "Tu es désinscrit de cette réunion 😢",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading || meeting == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Détails de la réunion")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = meeting!.data()!;
    final desc = data['description'] as String? ?? '';
    final type = data['type'] as String? ?? '';
    final address = data['address'] as String? ?? '';
    final date = (data['scheduledAt'] as Timestamp).toDate();
    final geo = data['location'] as GeoPoint?;
    final count = participants.length;

    return Scaffold(
      appBar: AppBar(title: Text("Détails de la réunion")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                desc,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text("Type : $type"),
              Text("Adresse : $address"),
              Text("Date : ${DateFormat.yMMMd().add_Hm().format(date)}"),
              Text("Participants : $count"),
              SizedBox(height: 16),
              if (geo != null)
                Container(
                  height: 180,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(geo.latitude, geo.longitude),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId("loc"),
                        position: LatLng(geo.latitude, geo.longitude),
                      ),
                    },
                    zoomControlsEnabled: false,
                  ),
                ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _toggleParticipation,
                icon: Icon(
                  isParticipating
                      ? Icons.remove_circle
                      : Icons.how_to_reg,
                ),
                label: Text(
                  isParticipating
                      ? "Me désinscrire"
                      : "Je participe",
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

