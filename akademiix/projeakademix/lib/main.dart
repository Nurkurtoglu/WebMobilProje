import 'package:flutter/material.dart';
import 'package:projeakademix/edit_profile_page.dart';
import 'package:projeakademix/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'initialize_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Calling initializeFirestore...');
    await initializeFirestore();
    debugPrint('Firestore initialization completed.');
    runApp(const Uygulamam());
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
}

class Uygulamam extends StatelessWidget {
  const Uygulamam({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage());
  }
}
