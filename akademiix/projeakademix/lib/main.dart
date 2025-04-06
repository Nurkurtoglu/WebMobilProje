import 'package:flutter/material.dart';
import 'package:projeakademix/edit_profile_page.dart';
import 'package:projeakademix/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const Uygulamam());
}

class Uygulamam extends StatelessWidget {
  const Uygulamam({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: LoginPage());
  }
}
