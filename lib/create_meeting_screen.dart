import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

const String googleApiKey = 'AIzaSyA-vdbLXiRZkXYwZ0NYDUbEA4mU6IO674I';
final places = GoogleMapsPlaces(apiKey: googleApiKey);

class CreateMeetingScreen extends StatefulWidget {
  @override
  _CreateMeetingScreenState createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  String selectedType = 'Speed Meeting';
  DateTime? selectedDateTime;
  GeoPoint? geoPoint;
  bool selectingAddress = false;

  // Nouveau : rayon en km
  double selectedRadius = 5.0;

  Future<void> _selectAddress() async {
    if (selectingAddress) return;
    setState(() => selectingAddress = true);
    try {
      final p = await PlacesAutocomplete.show(
        context: context,
        apiKey: googleApiKey,
        mode: Mode.overlay,
        language: 'fr',
        types: ['address'],
      );
      if (p != null) {
        final detail = await places.getDetailsByPlaceId(p.placeId!);
        final loc = detail.result.geometry?.location;
        setState(() {
          _addressCtrl.text = detail.result.formattedAddress ?? '';
          if (loc != null) geoPoint = GeoPoint(loc.lat, loc.lng);
        });
      }
    } catch (e) {
      print("Erreur autocomplétion : $e");
    } finally {
      setState(() => selectingAddress = false);
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _submitMeeting() async {
    if (!_formKey.currentState!.validate() ||
        selectedDateTime == null ||
        geoPoint == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : utilisateur non connecté")),
      );
      return;
    }

    // 1) Création du meeting avec le rayon
    final meetingRef = await FirebaseFirestore.instance
        .collection('meetings')
        .add({
      'description': _descCtrl.text.trim(),
      'type': selectedType,
      'address': _addressCtrl.text.trim(),
      'location': geoPoint,
      'radiusKm': selectedRadius,
      'createur_id': uid,
      'scheduledAt': Timestamp.fromDate(selectedDateTime!),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2) Notification aux users dans le périmètre
    final meetingLoc = geoPoint!;
    final usersSnap = await FirebaseFirestore.instance
        .collection('users')
        .get();

    for (final userDoc in usersSnap.docs) {
      final data = userDoc.data();
      if (data['location'] is GeoPoint) {
        final userLoc = data['location'] as GeoPoint;
        final distanceInMeters = Geolocator.distanceBetween(
          meetingLoc.latitude,
          meetingLoc.longitude,
          userLoc.latitude,
          userLoc.longitude,
        );

        // si l'utilisateur est dans le rayon choisi
        if (distanceInMeters <= selectedRadius * 1000) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .collection('notifications')
              .add({
            'type': 'new_meeting',
            'meetingId': meetingRef.id,
            'message':
                "Nouvel événement près de chez vous : ${_descCtrl.text.trim()}",
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Créer une réunion')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Description
              TextFormField(
                controller: _descCtrl,
                maxLength: 140,
                decoration: InputDecoration(
                  labelText: 'Description (140 caractères max)',
                ),
                validator: (v) =>
                    v != null && v.trim().isNotEmpty ? null : 'Champ requis',
              ),

              SizedBox(height: 12),
              // Type
              DropdownButtonFormField<String>(
                value: selectedType,
                onChanged: (val) => setState(() => selectedType = val!),
                items: [
                  'Speed Meeting',
                  'Présentation',
                  'Tour de Table',
                ]
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                decoration: InputDecoration(labelText: 'Type de réunion'),
              ),

              SizedBox(height: 12),
              // Adresse
              TextFormField(
                controller: _addressCtrl,
                readOnly: true,
                onTap: _selectAddress,
                decoration: InputDecoration(
                  labelText: 'Adresse (autocomplétée)',
                  suffixIcon: Icon(Icons.location_on),
                ),
                validator: (v) =>
                    geoPoint != null ? null : 'Sélectionnez une adresse valide',
              ),

              SizedBox(height: 12),
              // Date & heure
              ListTile(
                title: Text(
                  selectedDateTime != null
                      ? DateFormat('dd MMM yyyy – HH:mm')
                          .format(selectedDateTime!)
                      : 'Choisir date et heure',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),

              SizedBox(height: 12),
              // Nouveau : slider de distance
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rayon de notification : ${selectedRadius.toStringAsFixed(1)} km',
                  ),
                  Slider(
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${selectedRadius.toStringAsFixed(1)} km',
                    value: selectedRadius,
                    onChanged: (val) =>
                        setState(() => selectedRadius = val),
                  ),
                ],
              ),

              SizedBox(height: 24),
              // Bouton Créer
              ElevatedButton.icon(
                onPressed: _submitMeeting,
                icon: Icon(Icons.save),
                label: Text('Créer'),
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

  @override
  void dispose() {
    _descCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }
}

