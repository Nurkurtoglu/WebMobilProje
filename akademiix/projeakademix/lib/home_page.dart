import 'package:flutter/material.dart';
import 'package:projeakademix/edit_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
    required String firstName,
    required String lastName,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Klavye açıldığında ekran yeniden boyutlandırılır
      appBar: AppBar(
        title: Text("Ana Sayfa"),
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hoşgeldiniz',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfilePage()),
                  );
                },
                child: Text('Profili Düzenle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
