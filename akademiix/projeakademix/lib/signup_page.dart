import 'package:flutter/material.dart';
import 'package:projeakademix/services/auth_service.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late String _firstName;
  late String _lastName;
  late String _email;

  final AuthService _authService = AuthService(); // AuthService örneği

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // Firebase ile kullanıcı kaydı
        await _authService.signUp(
          _email,
          _passwordController.text,
          _firstName,
          _lastName,
        );

        // Başarılı kayıt sonrası giriş sayfasına yönlendirme
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Kayıt başarılı!")));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } catch (e) {
        // Hata mesajını göster
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Klavye açıldığında ekran yeniden boyutlandırılır
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Kayıt Ol',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      labelText: 'Ad',
                      labelStyle: TextStyle(color: Colors.blue),
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
                  SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Colors.blue,
                      ),
                      labelText: 'Soyad',
                      labelStyle: TextStyle(color: Colors.blue),
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
                  SizedBox(height: 10),
                  TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email, color: Colors.blue),
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.blue),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      String pattern =
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$';
                      RegExp regex = RegExp(pattern);
                      if (value == null || value.isEmpty) {
                        return 'Email adresinizi giriniz';
                      } else if (!regex.hasMatch(value)) {
                        return 'Geçerli bir email adresi giriniz';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _email = value!;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock, color: Colors.blue),
                      labelText: 'Şifre',
                      labelStyle: TextStyle(color: Colors.blue),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifrenizi giriniz';
                      } else if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalıdır';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.blue),
                      labelText: 'Şifre Tekrar',
                      labelStyle: TextStyle(color: Colors.blue),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifrenizi tekrar giriniz';
                      } else if (value != _passwordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 40,
                      ),
                    ),
                    onPressed: _signUp, // Firebase'e kullanıcı kaydetme işlemi
                    child: Text("Kayıt Ol", style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Giriş Yap",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
