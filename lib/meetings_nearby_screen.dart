import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class MeetingsNearbyScreen extends StatefulWidget {
  @override
  _MeetingsNearbyScreenState createState() => _MeetingsNearbyScreenState();
}

class _MeetingsNearbyScreenState extends State<MeetingsNearbyScreen> {
  double _radiusKm = 5.0;
  GeoPoint? _userLocation;
  List<DocumentSnapshot<Map<String, dynamic>>> _meetings = [];
  bool _loading = false;
  String _sortBy = 'distance';

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final loc = doc.data()?['location'] as GeoPoint?;
    if (loc != null) {
      setState(() => _userLocation = loc);
      _fetchMeetings();
    }
  }

  Future<void> _reGeolocate() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
    final pos = await Geolocator.getCurrentPosition();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final geo = GeoPoint(pos.latitude, pos.longitude);
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'location': geo});
    setState(() => _userLocation = geo);
    _fetchMeetings();
  }

  double _deg2rad(double deg) => deg * pi / 180;

  double _calculateDistance(GeoPoint a, GeoPoint b) {
    const R = 6371; // earth radius km
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);
    final h = sin(dLat/2)*sin(dLat/2) +
              sin(dLon/2)*sin(dLon/2)*cos(lat1)*cos(lat2);
    return R * 2 * atan2(sqrt(h), sqrt(1-h));
  }

  Future<void> _fetchMeetings() async {
    if (_userLocation == null) return;
    setState(() => _loading = true);

final now = DateTime.now();
final snap = await FirebaseFirestore.instance.collection('meetings').get();
final nearby = snap.docs.where((doc) {
  final geo = doc.data()['location'] as GeoPoint?;
  final date = (doc.data()['scheduledAt'] as Timestamp?)?.toDate();
  if (geo == null || date == null) return false;

  final dist = _calculateDistance(_userLocation!, geo);

  // ✅ On garde uniquement les réunions à venir, dans le rayon défini
  return dist <= _radiusKm && date.isAfter(now);
}).toList();

    nearby.sort((a, b) {
      if (_sortBy == 'distance') {
        final da = _calculateDistance(_userLocation!, a.data()!['location']);
        final db = _calculateDistance(_userLocation!, b.data()!['location']);
        return da.compareTo(db);
      } else {
        final ta = (a.data()!['scheduledAt'] as Timestamp).toDate();
        final tb = (b.data()!['scheduledAt'] as Timestamp).toDate();
        return ta.compareTo(tb);
      }
    });

    setState(() {
      _meetings = nearby;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Réunions autour de moi")),
      body: SafeArea(
        child: _loading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text("Rayon : ${_radiusKm.toStringAsFixed(1)} km"),
                              Expanded(
                                child: Slider(
                                  value: _radiusKm,
                                  min: 1,
                                  max: 100,
                                  divisions: 99,
                                  label: "${_radiusKm.toStringAsFixed(0)} km",
                                  onChanged: (v) => setState(() => _radiusKm = v),
                                  onChangeEnd: (_) => _fetchMeetings(),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _reGeolocate,
                                icon: Icon(Icons.gps_fixed),
                                label: Text("Me localiser"),
                              ),
                              DropdownButton<String>(
                                value: _sortBy,
                                items: [
                                  DropdownMenuItem(
                                      value: 'distance',
                                      child: Text("Tri : distance")),
                                  DropdownMenuItem(
                                      value: 'date', child: Text("Tri : date")),
                                ],
                                onChanged: (val) {
                                  setState(() => _sortBy = val!);
                                  _fetchMeetings();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _meetings.length,
                      itemBuilder: (ctx, i) {
                        final doc = _meetings[i];
                        final data = doc.data()!;
                        final title = data['description'] as String? ?? '';
                        final type = data['type'] as String? ?? '';
                        final address = data['address'] as String? ?? '';
                        final date = (data['scheduledAt'] as Timestamp).toDate();
                        final geo = data['location'] as GeoPoint;
                        final dist = _calculateDistance(_userLocation!, geo);

                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium),
                                      SizedBox(height: 4),
                                      Text("$type · $address"),
                                      SizedBox(height: 4),
                                      Text(
                                          DateFormat.yMMMd().add_Hm().format(date)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("${dist.toStringAsFixed(1)} km",
                                          textAlign: TextAlign.center),
                                      SizedBox(height: 8),
                                      TextButton(
onPressed: () async {
  final result = await Navigator.pushNamed(
    context,
    '/meetingDetails',
    arguments: doc.id,
  );
  if (result == true) {
    await _fetchMeetings(); // 🔄 On actualise les réunions
  }
},
                                        child: Text("Voir"),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

