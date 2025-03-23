import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late String _firstName;
  late String _lastName;
  late String _email;
  late String _password;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Kullanıcı bilgilerini yükleme
  void _loadUserData() {
    User? user = _auth.currentUser;

    if (user != null) {
      setState(() {
        _email = user.email ?? '';
        _firstName = user.displayName?.split(' ').first ?? '';
        _lastName = user.displayName?.split(' ').last ?? '';
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        User? user = _auth.currentUser;

        if (user != null) {
          // Firebase Authentication'da bilgileri güncelle
          await user.updateDisplayName("$_firstName $_lastName");
          await user.updateEmail(_email);

          if (_password.isNotEmpty) {
            await user.updatePassword(_password);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profil başarıyla güncellendi!")),
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: ${e.message}")));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Bir hata oluştu: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Klavye açıldığında ekran yeniden boyutlandırılır
      appBar: AppBar(
        title: const Text("Profili Düzenle"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                initialValue: _firstName,
                decoration: const InputDecoration(
                  labelText: 'Ad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Adınızı giriniz';
                  }
                  return null;
                },
                onSaved: (value) {
                  _firstName = value!;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _lastName,
                decoration: const InputDecoration(
                  labelText: 'Soyad',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Soyadınızı giriniz';
                  }
                  return null;
                },
                onSaved: (value) {
                  _lastName = value!;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  hintText: 'ornek@example.com',
                ),
                validator: (value) {
                  String pattern =
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
                  RegExp regex = RegExp(pattern);
                  if (value == null || value.isEmpty) {
                    return 'Email adresinizi giriniz';
                  } else if (!regex.hasMatch(value)) {
                    return 'Geçerli bir email adresi giriniz (örn: name@example.com)';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value!;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value ?? '';
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 40,
                  ),
                ),
                onPressed: _updateProfile,
                child: const Text("Kaydet", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
