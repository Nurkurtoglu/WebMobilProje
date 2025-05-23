import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:projeakademix/home_page.dart';
import 'package:projeakademix/login_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:badges/badges.dart' as custom_badges;
import 'edit_profile_page.dart';

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

  String _selectedLessonName = '';
  String _selectedWeek = '';

  Future<void> _pickFile(BuildContext context) async {
    // Önce form dialogunu göster
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ders Notu Yükleme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Ders Adı',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _selectedLessonName = value;
                },
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Hafta',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _selectedWeek = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Devam Et'),
              onPressed: () async {
                if (_selectedLessonName.isEmpty || _selectedWeek.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ).then((value) async {
      if (value == true) {
        try {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
          );

          if (result != null && result.files.single.bytes != null) {
            final fileBytes = result.files.single.bytes!;
            final originalFileName = result.files.single.name;
            final fileExtension = originalFileName.split('.').last;

            // Yeni dosya adı formatı: DersAdi HaftaX.uzanti
            final newFileName =
                '${_selectedLessonName} ${_selectedWeek}. hafta.$fileExtension';

            // Firebase Storage'a dosya yükleme
            final storageRef = FirebaseStorage.instance.ref().child(
              'ders_notlari/${FirebaseAuth.instance.currentUser?.uid}/$newFileName',
            );

            final uploadTask = storageRef.putData(fileBytes);
            final snapshot = await uploadTask.whenComplete(() {});
            final downloadUrl = await snapshot.ref.getDownloadURL();

            // Firestore'a dosya referansı ekleme
            await FirebaseFirestore.instance.collection('ders_notlari').add({
              'fileName': '${_selectedLessonName} ${_selectedWeek}. hafta',
              'fileUrl': downloadUrl,
              'userId': FirebaseAuth.instance.currentUser?.uid,
              'userEmail': FirebaseAuth.instance.currentUser?.email,
              'timestamp': FieldValue.serverTimestamp(),
            });

            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$_selectedLessonName - Hafta $_selectedWeek notu başarıyla yüklendi',
                ),
              ),
            );
          }
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Bir hata oluştu: $e')));
        }
      }
    });
  }

  Future<void> _addIlan(BuildContext context) async {
    if (ilanBasligi.isEmpty || ilanAciklamasi.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lütfen tüm alanları doldurun!")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('ilanlar').add({
        'title': ilanBasligi,
        'description': ilanAciklamasi,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'userEmail': FirebaseAuth.instance.currentUser?.email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Özel ilan başarıyla paylaşıldı!")),
      );

      setState(() {
        ilanBasligi = '';
        ilanAciklamasi = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Bir hata oluştu: $e")));
    }
  }

  Future<void> _openFileInBrowser(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'URL açılamıyor: $url';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Dosya açılamadı: $e")));
    }
  }

  Stream<int> getPendingNotificationsCount() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs.length;
          } catch (e) {
            debugPrint('Bildirim sayısı alınırken hata: $e');
            return 0;
          }
        });
  }

  Stream<QuerySnapshot> getNotificationsStream() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> handleNotification(
    String notificationId,
    bool isAccepted,
  ) async {
    try {
      final timestamp = FieldValue.serverTimestamp();
      final notificationRef = FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId);

      // Mevcut bildirimi al
      final notification = await notificationRef.get();
      final notificationData = notification.data() as Map<String, dynamic>;
      final senderId = notificationData['senderId'];
      final lessonTitle = notificationData['lessonTitle'] ?? 'Belirtilmemiş';

      // Mevcut bildirimi güncelle
      await notificationRef.update({
        'status': isAccepted ? 'accepted' : 'rejected',
        'updatedAt': timestamp,
        'responseTime': DateTime.now().toIso8601String(),
        'unread': false,
      });

      // Karşı tarafa bildirim gönder
      await FirebaseFirestore.instance.collection('notifications').add({
        'senderId': FirebaseAuth.instance.currentUser?.uid,
        'receiverId': senderId,
        'type': 'response',
        'status': isAccepted ? 'accepted' : 'rejected',
        'message':
            isAccepted
                ? '$lessonTitle dersi için isteğiniz kabul edildi.'
                : '$lessonTitle dersi için isteğiniz reddedildi.',
        'lessonTitle': lessonTitle,
        'timestamp': timestamp,
        'requestTime':
            notificationData['requestTime'] ?? DateTime.now().toIso8601String(),
        'responseTime': DateTime.now().toIso8601String(),
        'read': false,
        'unread': true,
      });
    } catch (e) {
      debugPrint('Bildirim güncelleme hatası: $e');
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Profilim",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            HomePage(firstName: widget.userName, lastName: ""),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text("Ana Sayfa", style: TextStyle(fontSize: 14)),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          StreamBuilder<int>(
            stream: getPendingNotificationsCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return IconButton(
                icon: custom_badges.Badge(
                  showBadge: count > 0,
                  badgeContent: Text(
                    count.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  child: Icon(Icons.notifications),
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return Container(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bildirimler',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('notifications')
                                        .where(
                                          'receiverId',
                                          isEqualTo:
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid,
                                        )
                                        .where(
                                          'status',
                                          whereIn: [
                                            'pending',
                                            'accepted',
                                            'rejected',
                                          ],
                                        )
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'Bir hata oluştu: ${snapshot.error}',
                                      ),
                                    );
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return Center(
                                      child: Text('Henüz bir bildirim yok.'),
                                    );
                                  }

                                  final notifications = snapshot.data!.docs;

                                  return ListView.builder(
                                    itemCount: notifications.length,
                                    itemBuilder: (context, index) {
                                      final notification = notifications[index];
                                      final senderId = notification['senderId'];
                                      final status = notification['status'];

                                      return FutureBuilder<DocumentSnapshot>(
                                        future:
                                            FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(senderId)
                                                .get(),
                                        builder: (context, userSnapshot) {
                                          if (userSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return ListTile(
                                              title: Text(
                                                'Bir kullanıcı ilanınıza özel ders isteği gönderdi.',
                                              ),
                                              subtitle: Text(
                                                'Gönderen bilgisi yükleniyor...',
                                              ),
                                            );
                                          }
                                          if (userSnapshot.hasError ||
                                              !userSnapshot.hasData ||
                                              !userSnapshot.data!.exists) {
                                            return ListTile(
                                              title: Text(
                                                'Bir kullanıcı ilanınıza özel ders isteği gönderdi.',
                                              ),
                                              subtitle: Text(
                                                'Gönderen bilgisi alınamadı.',
                                              ),
                                            );
                                          }
                                          final senderEmail =
                                              userSnapshot.data!['email'] ??
                                              'Bilinmiyor';

                                          final notificationData =
                                              notification.data()
                                                  as Map<String, dynamic>;
                                          final lessonTitle =
                                              notificationData['lessonTitle']
                                                  as String? ??
                                              'Belirtilmemiş';
                                          final type =
                                              notificationData['type']
                                                  as String? ??
                                              '';
                                          final message =
                                              notificationData['message']
                                                  as String? ??
                                              '';

                                          if (type == 'response') {
                                            final responseTime =
                                                notificationData['responseTime'];
                                            return ListTile(
                                              title: Text(message),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('Ders: $lessonTitle'),
                                                  if (responseTime != null)
                                                    Text(
                                                      'İşlem Tarihi: ${DateTime.parse(responseTime).toLocal().toString().split('.')[0]}',
                                                    ),
                                                ],
                                              ),
                                              leading: Icon(
                                                status == 'accepted'
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color:
                                                    status == 'accepted'
                                                        ? Colors.green
                                                        : Colors.red,
                                              ),
                                              trailing: IconButton(
                                                icon: Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () async {
                                                  try {
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                          'notifications',
                                                        )
                                                        .doc(notification.id)
                                                        .delete();
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Bildirim başarıyla silindi',
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Bildirim silinirken bir hata oluştu: $e',
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            );
                                          }

                                          return ListTile(
                                            title: Text(
                                              'Bir kullanıcı $lessonTitle dersi için özel ders isteği gönderdi.',
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Gönderen: $senderEmail'),
                                                Text('Ders: $lessonTitle'),
                                                Text('Durum: $status'),
                                                if ((notification.data()
                                                        as Map<
                                                          String,
                                                          dynamic
                                                        >)['responseTime'] !=
                                                    null)
                                                  Text(
                                                    'İşlem Tarihi: ${DateTime.parse((notification.data() as Map<String, dynamic>)['responseTime']).toLocal().toString().split('.')[0]}',
                                                  ),
                                              ],
                                            ),
                                            trailing:
                                                status == 'pending'
                                                    ? Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(
                                                            Icons.delete,
                                                            color: Colors.red,
                                                          ),
                                                          onPressed: () async {
                                                            try {
                                                              await FirebaseFirestore
                                                                  .instance
                                                                  .collection(
                                                                    'notifications',
                                                                  )
                                                                  .doc(
                                                                    notification
                                                                        .id,
                                                                  )
                                                                  .delete();
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Bildirim başarıyla silindi',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                              );
                                                            } catch (e) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Bildirim silinirken bir hata oluştu: $e',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        ),
                                                        SizedBox(width: 8),
                                                        ElevatedButton(
                                                          onPressed: () async {
                                                            try {
                                                              await handleNotification(
                                                                notification.id,
                                                                true,
                                                              );
                                                              if (!context
                                                                  .mounted)
                                                                return;
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    'İstek kabul edildi.',
                                                                  ),
                                                                ),
                                                              );
                                                            } catch (e) {
                                                              if (!context
                                                                  .mounted)
                                                                return;
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Bir hata oluştu: $e',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                          child: const Text(
                                                            'Kabul Et',
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () async {
                                                            try {
                                                              await handleNotification(
                                                                notification.id,
                                                                false,
                                                              );
                                                              if (!context
                                                                  .mounted)
                                                                return;
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    'İstek reddedildi.',
                                                                  ),
                                                                ),
                                                              );
                                                            } catch (e) {
                                                              if (!context
                                                                  .mounted)
                                                                return;
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Bir hata oluştu: $e',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              );
                                                            }
                                                          },
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                                foregroundColor:
                                                                    Colors
                                                                        .white,
                                                              ),
                                                          child: const Text(
                                                            'Reddet',
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                    : null,
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, size: 28),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
        // Add "Profili Düzenle" button to the top left corner
        leading: IconButton(
          icon: Icon(Icons.edit, size: 28, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => EditProfilePage(
                      firstName: widget.userName,
                      lastName: "", // Provide the last name if available
                    ),
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade100.withOpacity(0.5),
                Colors.white.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade200,
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        widget.userName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.email,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                // Özel İlan Paylaşımı
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Özel Ders İlan Paylaşımı",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          decoration: InputDecoration(
                            labelText: "İlan Başlığı",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.blue.shade50,
                          ),
                          onChanged: (value) {
                            ilanAciklamasi = value;
                          },
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _addIlan(context),
                          child: Center(
                            child: Text(
                              "İlanı Paylaş",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    Colors.white, // Updated to a lighter color
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // Combine "Dosya Yükleme" and "Ders Notlarınız" sections into a single card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Dosya Yükleme ve Ders Notlarınız",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => _pickFile(context),
                          icon: Icon(
                            Icons.upload_file,
                            size: 24,
                            color: Colors.white,
                          ), // Updated icon color
                          label: Text(
                            "Dosya Yükle",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Updated to a lighter color
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('ders_notlari')
                                  .where(
                                    'userId',
                                    isEqualTo:
                                        FirebaseAuth
                                            .instance
                                            .currentUser
                                            ?.uid ??
                                        '',
                                  )
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  "Bir hata oluştu: ${snapshot.error}",
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text(
                                  "Henüz bir ders notu paylaşılmamış.",
                                ),
                              );
                            }

                            final dersNotlari = snapshot.data!.docs;

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: dersNotlari.length,
                              itemBuilder: (context, index) {
                                final not = dersNotlari[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: Icon(Icons.file_present),
                                    title: Text(
                                      not['fileName'] ?? 'Dosya adı yok',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Yükleme Tarihi: ${not['timestamp']?.toDate().toString().split('.')[0] ?? 'Tarih yok'}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    onTap: () async {
                                      final url = not['fileUrl'];
                                      if (url != null) {
                                        await _openFileInBrowser(url, context);
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Dosya URL'si bulunamadı.",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        try {
                                          // Firestore'dan dosyayı sil
                                          await FirebaseFirestore.instance
                                              .collection('ders_notlari')
                                              .doc(not.id)
                                              .delete();

                                          // Firebase Storage'dan dosyayı sil
                                          if (not['fileUrl'] != null) {
                                            final fileRef = FirebaseStorage
                                                .instance
                                                .refFromURL(not['fileUrl']);
                                            await fileRef.delete();
                                          }

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Ders notu başarıyla silindi.',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Ders notu silinirken bir hata oluştu: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                // "İlanlarınız" section restored
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "İlanlarınız",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        SizedBox(height: 8),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('ilanlar')
                                  .where(
                                    'userId',
                                    isEqualTo:
                                        FirebaseAuth
                                            .instance
                                            .currentUser
                                            ?.uid ??
                                        '',
                                  )
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text(
                                  "Bir hata oluştu: ${snapshot.error}",
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text("Henüz bir ilan paylaşılmamış."),
                              );
                            }

                            final ilanlar = snapshot.data!.docs;

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: ilanlar.length,
                              itemBuilder: (context, index) {
                                final ilan = ilanlar[index];
                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: Icon(Icons.announcement),
                                    title: Text(ilan['title'] ?? 'Başlık yok'),
                                    subtitle: Text(
                                      ilan['description'] ?? 'Açıklama yok',
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        try {
                                          await FirebaseFirestore.instance
                                              .collection('ilanlar')
                                              .doc(ilan.id)
                                              .delete();

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'İlan başarıyla silindi.',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'İlan silinirken bir hata oluştu: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bildirimler')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('notifications')
                .where(
                  'receiverId',
                  isEqualTo: FirebaseAuth.instance.currentUser?.uid,
                )
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Bir hata oluştu: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Henüz bir bildirim yok.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final status = notification['status'];

              return Card(
                child: ListTile(
                  title: Text(
                    'Bir kullanıcı ilanınıza özel ders isteği gönderdi.',
                  ),
                  subtitle: Text('Durum: $status'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
