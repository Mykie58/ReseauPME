import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  GeoPoint? _geoPoint;
  bool _loading = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          final prenom = data['prenom'];
          _prenomCtrl.text = prenom is String ? prenom : '';

          final nom = data['nom'];
          _nomCtrl.text = nom is String ? nom : '';

          final company = data['company'];
          _companyCtrl.text = company is String ? company : '';

          final description = data['description'];
          _descriptionCtrl.text = description is String ? description : '';

          final location = data['location'];
          _geoPoint = location is GeoPoint ? location : null;
        });
      }
    }
  }

  Future<void> _updateLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'location': GeoPoint(position.latitude, position.longitude),
      });
      setState(() {
        _geoPoint = GeoPoint(position.latitude, position.longitude);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'prenom': _prenomCtrl.text.trim(),
        'nom': _nomCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
      });
    }

    setState(() {
      _loading = false;
    });

    Navigator.of(context).pop(); // Retour à l'écran précédent
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _companyCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng? position = _geoPoint != null
        ? LatLng(_geoPoint!.latitude, _geoPoint!.longitude)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text('Modifier mon profil')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _prenomCtrl,
                decoration: InputDecoration(labelText: 'Prénom'),
                validator: (v) => v != null && v.trim().length >= 2 ? null : 'Prénom invalide',
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _nomCtrl,
                decoration: InputDecoration(labelText: 'Nom'),
                validator: (v) => v != null && v.trim().length >= 2 ? null : 'Nom invalide',
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _companyCtrl,
                decoration: InputDecoration(labelText: 'Société'),
                validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Ce champ est requis',
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: InputDecoration(labelText: 'Description'),
                maxLength: 140,
              ),
              SizedBox(height: 24),
              if (position != null)
                Container(
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: position, zoom: 15),
                    markers: {
                      Marker(markerId: MarkerId('me'), position: position),
                    },
                    onMapCreated: (controller) => _mapController = controller,
                    myLocationEnabled: false,
                    zoomControlsEnabled: false,
                  ),
                ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _updateLocation,
                icon: Icon(Icons.gps_fixed),
                label: Text('Re-géolocaliser ma position'),
              ),
              SizedBox(height: 24),
              _loading
                  ? CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: Icon(Icons.save),
                      label: Text('Enregistrer'),
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
