import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserDescriptionScreen extends StatefulWidget {
  @override
  _UserDescriptionScreenState createState() => _UserDescriptionScreenState();
}

class _UserDescriptionScreenState extends State<UserDescriptionScreen> {
  final _descCtrl = TextEditingController();
  bool _saving = false;

  void _saveDescription() async {
    if (_descCtrl.text.trim().length > 140) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'description': _descCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      Navigator.of(context).pushReplacementNamed('/home');
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Décris-toi')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Text('En une phrase (140 caractères max) 👇'),
            SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLength: 140,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Passionné par l’innovation locale...',
              ),
            ),
            SizedBox(height: 24),
            _saving
                ? CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _saveDescription,
                    icon: Icon(Icons.save),
                    label: Text("Enregistrer"),
                  ),
          ],
        ),
      ),
    );
  }
}
