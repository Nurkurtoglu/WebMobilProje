import 'package:flutter/material.dart';
import 'package:projeakademix/services/auth_service.dart';
import 'profile_page.dart'; // Profil sayfası
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late String _email;
  late String _password;
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService(); // AuthService örneği

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // Firebase ile giriş yap
        final user = await _authService.signIn(_email, _password);

        // Kullanıcı bilgilerini al
        final userName = user?.displayName ?? "Bilinmeyen Kullanıcı";
        final email = user?.email ?? "Bilinmeyen E-posta";

        // Başarılı giriş sonrası profil sayfasına yönlendirme
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ProfilePage(
                  userName: userName,
                  email: email,
                  firstName: null,
                  lastName: null,
                ),
          ),
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
            colors: [Colors.purple.shade200, Colors.purple.shade700],
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
                    autofocus: true,
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
                  SizedBox(height: 20),
                  TextFormField(
                    obscureText: true,
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
                    onPressed: _signIn, // Giriş yapma işlemi
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
                        onPressed: () {
                          // Şifremi unuttum işlemi burada yapılabilir
                        },
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
