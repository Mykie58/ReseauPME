import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SendMessageScreen extends StatefulWidget {
  static const routeName = '/sendMessage';

  @override
  _SendMessageScreenState createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final _msgCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool sending = false;

  late String meetingId;
  late List<String> participants;
  bool _argsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsLoaded) {
      final args = ModalRoute.of(context)!.settings.arguments
          as Map<String, dynamic>;
      meetingId = args['meetingId'] as String;
      participants = List<String>.from(args['participants'] as List);
      _argsLoaded = true;
    }
  }

  Future<void> _sendMessages() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => sending = true);

    final text = _msgCtrl.text.trim();
    final batch = FirebaseFirestore.instance.batch();
    final now = FieldValue.serverTimestamp();

    for (final uid in participants) {
      final notifRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc();
      batch.set(notifRef, {
        'type': 'meeting_message',
        'meetingId': meetingId,
        'message': text,
        'timestamp': now,
      });
    }

    await batch.commit();

    setState(() => sending = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nouveau message")),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _msgCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: "Votre message aux participants",
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty ? null : 'Champ requis',
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: sending
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send),
              label: Text(sending ? 'Envoi...' : 'Envoyer'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
              onPressed: sending ? null : _sendMessages,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }
}

