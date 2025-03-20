import 'package:flutter/material.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late String _username;
  late String _password;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade200, Colors.purple.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Form(
              key: _formKey, // Form widgetini ekliyoruz
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //Image.asset('../assets/images/1.png', width: 100, height: 100),
                  SizedBox(height: 20),
                  Text(
                    'AkademiX',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 40),
                  TextFormField(
                    autofocus: true, // Klavye otomatik olarak açılır
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.email, color: Colors.purple),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple, width: 2),
                      ),
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.purple),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      // Email format kontrolü
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
                      _username = value!;
                    },
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    obscureText: true, // Şifreyi gizle
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock, color: Colors.purple),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.purple, width: 2),
                      ),
                      labelText: 'Şifre',
                      labelStyle: TextStyle(color: Colors.purple),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      // Şifre kontrolü (en az 6 karakter)
                      if (value == null || value.isEmpty) {
                        return 'Şifrenizi giriniz';
                      } else if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalıdır';
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _password = value!;
                    },
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 40,
                      ),
                    ),
                    onPressed: () {
                      // Formu kontrol et ve doğrulama yap
                      if (_formKey.currentState!.validate()) {
                        // Formu kaydet
                        _formKey.currentState!.save();
                        // Giriş işlemini burada yapabilirsiniz
                        print('Email: $_username, Şifre: $_password');
                      }
                    },
                    child: Text("Giriş Yap", style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpPage(),
                            ),
                          );
                        },
                        child: Text(
                          "Üye Ol",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "Şifremi Unuttum",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
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
