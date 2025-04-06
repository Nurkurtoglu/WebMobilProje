import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:projeakademix/home_page.dart';
import 'package:projeakademix/login_page.dart';

class ProfilePage extends StatefulWidget {
  final String userName;
  final String email;

  const ProfilePage({
    Key? key,
    required this.userName,
    required this.email,
    required firstName,
    required lastName,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String ilanBasligi = '';
  String ilanAciklamasi = '';

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'], // İzin verilen dosya türleri
      );

      if (result != null) {
        final fileName = result.files.single.name;

        // Web platformu için bytes kullanımı
        if (result.files.single.bytes != null) {
          final fileBytes = result.files.single.bytes!;

          // Firebase Storage'a dosya yükleme
          final storageRef = FirebaseStorage.instance.ref().child(
            'ders_notlari/${FirebaseAuth.instance.currentUser?.uid}/$fileName',
          );

          final uploadTask = storageRef.putData(fileBytes);

          // Yükleme tamamlandıktan sonra dosya URL'sini al
          final snapshot = await uploadTask.whenComplete(() {});
          final downloadUrl = await snapshot.ref.getDownloadURL();

          // Firestore'a dosya referansı ekleme
          await FirebaseFirestore.instance.collection('ders_notlari').add({
            'fileName': fileName,
            'fileUrl': downloadUrl,
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Dosya başarıyla yüklendi: $fileName")),
          );
        }
        // Mobil platform için path kullanımı
        else if (result.files.single.path != null) {
          final file = File(result.files.single.path!);

          // Firebase Storage'a dosya yükleme
          final storageRef = FirebaseStorage.instance.ref().child(
            'ders_notlari/${FirebaseAuth.instance.currentUser?.uid}/$fileName',
          );

          final uploadTask = storageRef.putFile(file);

          // Yükleme tamamlandıktan sonra dosya URL'sini al
          final snapshot = await uploadTask.whenComplete(() {});
          final downloadUrl = await snapshot.ref.getDownloadURL();

          // Firestore'a dosya referansı ekleme
          await FirebaseFirestore.instance.collection('ders_notlari').add({
            'fileName': fileName,
            'fileUrl': downloadUrl,
            'userId': FirebaseAuth.instance.currentUser?.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Dosya başarıyla yüklendi: $fileName")),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Dosya seçimi iptal edildi.")));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Dosya seçimi iptal edildi.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Bir hata oluştu: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("Profilim"),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Taşma hatasını önlemek için eklendi
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kullanıcı Bilgileri
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade200,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  widget.userName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Text(
                  widget.email,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              SizedBox(height: 24),

              // Özel İlan Paylaşımı
              Text(
                "Özel İlan Paylaşımı",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  labelText: "İlan Başlığı",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  ilanBasligi = value;
                },
              ),
              SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "İlan Açıklaması",
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  ilanAciklamasi = value;
                },
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Boş alan kontrolü
                  if (ilanBasligi.isEmpty || ilanAciklamasi.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lütfen tüm alanları doldurun!")),
                    );
                    return;
                  }

                  // Firestore'a ilan ekleme
                  FirebaseFirestore.instance.collection('ilanlar').add({
                    'title': ilanBasligi,
                    'description': ilanAciklamasi,
                    'userId': FirebaseAuth.instance.currentUser?.uid,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Özel ilan paylaşıldı!")),
                  );

                  // Alanları temizleme
                  setState(() {
                    ilanBasligi = '';
                    ilanAciklamasi = '';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
                child: Text("İlanı Paylaş"),
              ),
              SizedBox(height: 24),

              // Ders Notu Paylaşımı
              Text(
                "Ders Notu Paylaşımı",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _pickFile(context), // Dosya seçimi
                icon: Icon(Icons.upload_file),
                label: Text("Dosya Yükle"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                ),
              ),
              SizedBox(height: 24),

              // Kullanıcı Paylaşımları
              Text(
                "Paylaşımlarınız",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('ders_notlari')
                        .where(
                          'userId',
                          isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                        )
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("Bir hata oluştu: ${snapshot.error}"),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("Henüz bir paylaşım yapılmamış."),
                    );
                  }

                  final notes = snapshot.data!.docs;

                  return ListView.builder(
                    shrinkWrap: true, // Taşma hatasını önlemek için eklendi
                    physics:
                        NeverScrollableScrollPhysics(), // Ana kaydırma ile uyumlu
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: Icon(Icons.file_present),
                          title: Text(note['fileName']),
                          subtitle: Text(
                            "Yükleme Tarihi: ${note['timestamp']?.toDate().toString() ?? 'Tarih yok'}",
                          ),
                          onTap: () {
                            // Dosya detayına yönlendirme veya indirme işlemi
                          },
                        ),
                      );
                    },
                  );
                },
              ),
              SizedBox(height: 16),

              // Ana Sayfa Butonu
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => HomePage(
                              firstName: widget.userName,
                              lastName: "",
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text("Ana Sayfa", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
