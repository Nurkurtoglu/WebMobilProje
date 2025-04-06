import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Kullanıcıyı kaydetme (Üye olma)
  Future<User?> signUp(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Kullanıcı bilgilerini güncelle
      await userCredential.user?.updateDisplayName("$firstName $lastName");

      // Firestore'a kullanıcı bilgilerini kaydet
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .set({
            'firstName': firstName,
            'lastName': lastName,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Bir hata oluştu.";
    }
  }

  // Kullanıcı giriş yapma
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Bir hata oluştu.";
    }
  }

  // Kullanıcı çıkış yapma
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Şu anki kullanıcıyı alma
  User? get currentUser {
    return _auth.currentUser;
  }
}
