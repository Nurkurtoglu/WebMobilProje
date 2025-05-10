import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> initializeFirestore() async {
  final firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print('Kullanıcı oturum açmamış. Firestore başlatılamadı.');
    return;
  }

  try {
    print('Firestore initialized without example data.');
  } catch (e) {
    print('Error initializing Firestore: ${e.toString()}');
  }
}
