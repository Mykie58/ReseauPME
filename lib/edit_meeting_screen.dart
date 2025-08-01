import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'send_message_screen.dart';
import 'package:reseaupme/participants_screen.dart';


class EditMeetingScreen extends StatefulWidget {
  static const routeName = '/editMeeting';

  @override
  _EditMeetingScreenState createState() => _EditMeetingScreenState();
}

class _EditMeetingScreenState extends State<EditMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String selectedType = 'Réunion';
  DateTime? selectedDateTime;
  GeoPoint? geoPoint;
  DocumentSnapshot? meeting;
  bool loading = true;
  List<String> participants = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (meeting == null) {
      meeting =
          ModalRoute.of(context)!.settings.arguments as DocumentSnapshot?;
      _loadInitialValues();
    }
  }

  void _loadInitialValues() {
    final data = meeting?.data() as Map<String, dynamic>? ?? {};
    _descriptionCtrl.text = data['description'] ?? '';
    _addressCtrl.text = data['adresse'] ?? data['address'] ?? '';
    selectedType = data['type'] ?? 'Réunion';
    geoPoint = data['location'] as GeoPoint?;
    final ts = data['scheduledAt'] as Timestamp?;
    if (ts != null) selectedDateTime = ts.toDate();
    participants = List<String>.from(data['participants'] ?? []);
    setState(() => loading = false);
  }

  Future<void> _selectAddress() async {
    // votre code d'autocomplete (omitted for brevity)
  }

  Future<void> _selectDateTime() async {
    // votre code de DatePicker + TimePicker (omitted for brevity)
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() ||
        selectedDateTime == null ||
        geoPoint == null) return;

    await FirebaseFirestore.instance
        .collection('meetings')
        .doc(meeting!.id)
        .update({
      'description': _descriptionCtrl.text.trim(),
      'type': selectedType,
      'adresse': _addressCtrl.text.trim(),
      'location': geoPoint,
      'scheduledAt': Timestamp.fromDate(selectedDateTime!),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Réunion mise à jour ✅")),
    );
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Supprimer la réunion"),
        content: Text("Êtes-vous sûr de vouloir supprimer cette réunion ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) await _deleteMeeting();
  }

  Future<void> _deleteMeeting() async {
    final data = meeting!.data() as Map<String, dynamic>;
    final ids = List<String>.from(data['participants'] ?? []);
    await FirebaseFirestore.instance
        .collection('meetings')
        .doc(meeting!.id)
        .delete();

    final batch = FirebaseFirestore.instance.batch();
    final now = FieldValue.serverTimestamp();
    for (var uid in ids) {
      final notif = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc();
      batch.set(notif, {
        'type': 'meeting_deleted',
        'meetingId': meeting!.id,
        'message': 'La réunion "${data['description']}" a été supprimée.',
        'timestamp': now,
      });
    }
    await batch.commit();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Réunion supprimée 🗑️")),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modifier la réunion")),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // DESCRIPTION
                    TextFormField(
                      controller: _descriptionCtrl,
                      decoration: InputDecoration(labelText: "Description"),
                      validator: (v) =>
                          v != null && v.trim().isNotEmpty ? null : "Champ requis",
                    ),
                    SizedBox(height: 12),

                    // TYPE
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      items: [
                        'Réunion',
                        'Speed Meeting',
                        'Tour de Table',
                        'Présentation',
                      ]
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => selectedType = v!),
                      decoration: InputDecoration(labelText: 'Type'),
                    ),
                    SizedBox(height: 12),

                    // ADRESSE
                    TextFormField(
                      controller: _addressCtrl,
                      readOnly: true,
                      onTap: _selectAddress,
                      decoration: InputDecoration(
                        labelText: "Adresse",
                        suffixIcon: Icon(Icons.location_on),
                      ),
                      validator: (v) =>
                          geoPoint != null ? null : "Adresse invalide",
                    ),
                    SizedBox(height: 12),

                    // DATE & HEURE
                    ListTile(
                      title: Text(
                        selectedDateTime != null
                            ? DateFormat('dd/MM/yyyy – HH:mm').format(selectedDateTime!)
                            : 'Choisir date et heure',
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: _selectDateTime,
                    ),
                    SizedBox(height: 12),

                    // ENVOYER UN MESSAGE
                    ElevatedButton.icon(
                      icon: Icon(Icons.message),
                      label: Text("Envoyer un message"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                      onPressed: participants.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).pushNamed(
                                SendMessageScreen.routeName,
                                arguments: {
                                  'meetingId': meeting!.id,
                                  'participants': participants,
                                },
                              );
                            },
                    ),
                    SizedBox(height: 12),
// LISTE INSCRITS
		ElevatedButton.icon(
  icon: Icon(Icons.people),
  label: Text("Participants"),
  style: ElevatedButton.styleFrom(
    minimumSize: Size(double.infinity, 48),
  ),
  onPressed: participants.isEmpty
      ? null
      : () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ParticipantsScreen(
                participantIds: participants,
              ),
            ),
          );
        },
),
SizedBox(height: 12),


                    // ENREGISTRER
                    ElevatedButton.icon(
                      onPressed: _saveChanges,
                      icon: Icon(Icons.save),
                      label: Text("Enregistrer"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                    SizedBox(height: 12),

                    // SUPPRIMER
                    ElevatedButton.icon(
                      onPressed: _confirmDelete,
                      icon: Icon(Icons.delete_forever),
                      label: Text("Supprimer la réunion"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }
}

