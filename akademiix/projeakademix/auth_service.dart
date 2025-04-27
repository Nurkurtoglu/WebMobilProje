import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      // Kullanıcıyı Firebase Authentication ile kaydet
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Kullanıcı null kontrolü
      if (userCredential.user == null) {
        throw Exception('Kullanıcı oluşturulamadı.');
      }

      // Kullanıcı bilgilerini Firestore'a yaz
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Kullanıcının displayName'ini Firebase Authentication'da güncelle
      await userCredential.user!.updateDisplayName('$firstName $lastName');
    } catch (e) {
      // Hata durumunda kullanıcıya bilgi ver
      print('Kullanıcı kaydı sırasında hata oluştu: $e');
      rethrow; // Hatanın üst katmana iletilmesi için
    }
  }
}
