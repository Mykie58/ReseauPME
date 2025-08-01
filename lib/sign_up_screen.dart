import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _prenomCtrl   = TextEditingController();
  final _nomCtrl      = TextEditingController();
  final _companyCtrl  = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      // 🔐 1. Création du compte
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final uid = cred.user!.uid;

      // 📄 2. Enregistrement Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'prenom': _prenomCtrl.text.trim(),
        'nom': _nomCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 📍 3. Géolocalisation
      await _saveUserLocation(uid);

      // 🚀 4. Navigation
      Navigator.of(context).pushReplacementNamed('/description');
    } on FirebaseAuthException catch (e) {
      final message = e.message ?? 'Une erreur inconnue est survenue';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveUserLocation(String uid) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'location': GeoPoint(position.latitude, position.longitude),
        });
      }
    } catch (e) {
      print("Erreur localisation: $e");
    }
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("S'inscrire")),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _prenomCtrl,
                  decoration: InputDecoration(labelText: 'Prénom'),
                  validator: (v) =>
                      v != null && v.trim().length >= 2
                          ? null
                          : 'Prénom trop court',
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nomCtrl,
                  decoration: InputDecoration(labelText: 'Nom'),
                  validator: (v) =>
                      v != null && v.trim().length >= 2
                          ? null
                          : 'Nom trop court',
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _companyCtrl,
                  decoration: InputDecoration(labelText: 'Société'),
                  validator: (v) =>
                      v != null && v.trim().isNotEmpty
                          ? null
                          : 'Ce champ est requis',
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      v != null && v.contains('@')
                          ? null
                          : 'Adresse email invalide',
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Mot de passe'),
                  validator: (v) =>
                      v != null && v.length >= 6
                          ? null
                          : '6 caractères minimum',
                ),
                SizedBox(height: 32),
                _loading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _register,
                        child: Text("S'inscrire"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                        ),
                      ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                  child: Text("Vous avez déjà un compte ? Se connecter"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

