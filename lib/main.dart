import 'package:reseaupme/user_description_screen.dart';
import 'package:reseaupme/meetings_nearby_screen.dart';
import 'package:reseaupme/create_meeting_screen.dart';
import 'package:reseaupme/edit_profile_screen.dart';
import 'package:reseaupme/meeting_details_screen.dart';
import 'package:reseaupme/notifications_screen.dart';
import 'package:reseaupme/my_meetings_screen.dart';
import 'package:reseaupme/edit_meeting_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Pour Firebase.initializeApp et FirebaseOptions
import 'package:reseaupme/sign_up_screen.dart';
import 'package:reseaupme/login_screen.dart';
import 'package:reseaupme/logged_in_screen.dart';
import 'package:reseaupme/send_message_screen.dart';
import 'package:reseaupme/participants_screen.dart';




const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyAM7kFE_rRJzJBEmsPLD1-uwpwDAFQl634",
  authDomain: "reseaupme-3a166.firebaseapp.com",
  projectId: "reseaupme-3a166",
  storageBucket: "reseaupme-3a166.appspot.com",
  messagingSenderId: "874039465714",
  appId: "1:874039465714:web:f3214e4ee353d6fb3ee26b",
  measurementId: "G-C1RWRFD78M",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: firebaseConfig);
  } catch (e) {
    print("Erreur d'initialisation Firebase : $e");
  }
  runApp(ReseauPMEApp());
}



class ReseauPMEApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RéseauPME',
      initialRoute: '/',
routes: {
  '/': (context) => HomeScreen(),               // Accueil public
  '/signup': (context) => SignUpScreen(),
  '/login': (context) => LoginScreen(),
  '/home': (context) => LoggedInScreen(),       // Page après connexion
  '/description': (context) => UserDescriptionScreen(), // Bio 140 caractères
  '/meetingsNearby': (context) => MeetingsNearbyScreen(), // Réunions proches
  '/createMeeting': (context) => CreateMeetingScreen(),   // Création d'événement
  '/editProfile': (context) => EditProfileScreen(),       // Modifier profil
  '/meetingDetails': (context) => MeetingDetailsScreen(),
  '/notifications': (context) => NotificationsScreen(),
  '/myMeetings': (context) => MyMeetingsScreen(),
'/editMeeting': (context) => EditMeetingScreen(),
    '/sendMessage': (context)      => SendMessageScreen(),
     


}
,
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🌟 Logo avec effet d’ombre et forme arrondie
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 32),

              // 🎯 Titre et slogan
              Text(
                'RéseauPME',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue[900],
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Rencontrez les entrepreneurs près de chez vous',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 40),

              // 🔘 Boutons
				ElevatedButton.icon(
				  onPressed: () {
					Navigator.of(context).pushNamed('/signup');
				  },
				  icon: Icon(Icons.person_add),
				  label: Text("S’inscrire"),
				  style: ElevatedButton.styleFrom(
					minimumSize: Size(double.infinity, 48),
					backgroundColor: Colors.blueAccent,
					textStyle: TextStyle(fontSize: 16),
				  ),
				),
              SizedBox(height: 16),
				OutlinedButton.icon(
				onPressed: () {
  Navigator.of(context).pushNamed('/login');
},
				  icon: Icon(Icons.login),
				  label: Text("Se connecter"),
				  style: OutlinedButton.styleFrom(
					minimumSize: Size(double.infinity, 48),
					textStyle: TextStyle(fontSize: 16),
				  ),
				),
            ],
          ),
        ),
      ),
    );
  }
}
