import 'package:flutter/material.dart';
import 'package:projeakademix/edit_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeakademix/profile_page.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String searchQuery = '';
  int selectedIndex = 0;

  final Stream<QuerySnapshot> featuredContentStream =
      FirebaseFirestore.instance
          .collection(
            'ders_notlari',
          ) // collectionGroup yerine collection kullanıldı
          .orderBy('timestamp', descending: true)
          .snapshots();

  final List<String> categories = ['Ders Notları', 'İlanları'];

  final Stream<QuerySnapshot> ilanlarStream =
      FirebaseFirestore.instance
          .collection('ilanlar')
          .orderBy('timestamp', descending: true)
          .snapshots();

  final Stream<QuerySnapshot> dersNotlariStream =
      FirebaseFirestore.instance
          .collection('ders_notlari')
          .orderBy('timestamp', descending: true)
          .snapshots();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("Ana Sayfa"),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: CustomSearchDelegate());
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade700),
              child: Text(
                'Menü',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Ana Sayfa'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Ayarlar'),
              onTap: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final userDoc =
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get();

                  if (userDoc.exists) {
                    final userData = userDoc.data();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => EditProfilePage(
                              firstName: userData?['firstName'] ?? 'Ad',
                              lastName: userData?['lastName'] ?? 'Soyad',
                            ),
                      ),
                    );
                  } else {
                    // Handle case where user document does not exist
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kullanıcı bilgileri bulunamadı.'),
                      ),
                    );
                  }
                } else {
                  // Handle case where user is not logged in
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Giriş yapmanız gerekiyor.')),
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Öne Çıkanlar Bölümü
          Container(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Öne Çıkanlar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: featuredContentStream,
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
                        child: Text("Henüz öne çıkan içerik bulunamadı."),
                      );
                    }
                    final featuredItems = snapshot.data!.docs;
                    return Container(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: featuredItems.length,
                        itemBuilder: (context, index) {
                          final item = featuredItems[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 10),
                            child: Container(
                              width:
                                  200, // Genişliği sınırlamak için sabit bir değer
                              padding: EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Text(
                                      item['fileName'] ??
                                          'Başlık yok', // Varsayılan değer
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow:
                                          TextOverflow
                                              .ellipsis, // Taşmayı önlemek için
                                      maxLines: 1, // Maksimum 1 satır göster
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Flexible(
                                    child: Text(
                                      "Tarih: ${item['timestamp']?.toDate().toString() ?? 'Tarih yok'}",
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow
                                              .ellipsis, // Taşmayı önlemek için
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Kategoriler
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color:
                          selectedIndex == index
                              ? Colors.blue.shade700
                              : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        categories[index],
                        style: TextStyle(
                          color:
                              selectedIndex == index
                                  ? Colors.white
                                  : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Genel Akış
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedIndex == 1 ? ilanlarStream : dersNotlariStream,
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
                  return Center(child: Text("Henüz bir içerik bulunamadı."));
                }
                final items = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(item['userId'])
                              .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (userSnapshot.hasError || !userSnapshot.hasData) {
                          return ListTile(
                            title: Text(
                              selectedIndex == 1
                                  ? item['title'] ?? 'Başlık yok'
                                  : item['fileName'] ?? 'Dosya adı yok',
                            ),
                            subtitle: Text("Kullanıcı bilgisi alınamadı."),
                          );
                        }
                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>?;
                        final userEmail = userData?['email'] ?? 'Bilinmiyor';
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 10),
                          child: ListTile(
                            leading: Icon(
                              selectedIndex == 1
                                  ? Icons.announcement
                                  : Icons.file_present,
                            ),
                            title: Text(
                              selectedIndex == 1
                                  ? item['title'] ?? 'Başlık yok'
                                  : item['fileName'] ?? 'Dosya adı yok',
                            ),
                            subtitle: Text(
                              selectedIndex == 1
                                  ? "${item['description'] ?? 'Açıklama yok'}\nE-posta: $userEmail\nTarih: ${item['timestamp']?.toDate().toString() ?? 'Tarih yok'}"
                                  : "Yükleme Tarihi: ${item['timestamp']?.toDate().toString() ?? 'Tarih yok'}\nE-posta: $userEmail",
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text(
                                        selectedIndex == 1
                                            ? item['title'] ?? 'Başlık yok'
                                            : item['fileName'] ??
                                                'Dosya adı yok',
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (selectedIndex == 1)
                                            Text(
                                              "Açıklama: ${item['description'] ?? 'Açıklama yok'}",
                                            ),
                                          Text("E-posta: $userEmail"),
                                          Text(
                                            "Tarih: ${item['timestamp']?.toDate().toString() ?? 'Tarih yok'}",
                                          ),
                                          if (selectedIndex != 1)
                                            TextButton.icon(
                                              onPressed: () async {
                                                final url = item['fileUrl'];
                                                if (url != null) {
                                                  await _openFileInBrowser(
                                                    url,
                                                    context,
                                                  );
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
                                              icon: Icon(Icons.download),
                                              label: Text("Dosyayı İndir"),
                                            ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text("Kapat"),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) async {
          if (index == 1) {
            // Profil button
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ProfilePage(
                        userName: user.displayName ?? 'Kullanıcı',
                        email: user.email ?? 'Email bulunamadı',
                        firstName: null,
                        lastName: null,
                      ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Giriş yapmanız gerekiyor.')),
              );
            }
          } else {
            setState(() {
              selectedIndex = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'İlanlarım'),
        ],
      ),
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  final List<String> searchResults = [
    'Kullanıcı 1',
    'Kullanıcı 2',
    'Kullanıcı 3',
    'İçerik 1',
    'İçerik 2',
  ];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results =
        searchResults
            .where(
              (element) => element.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index]),
          onTap: () {
            // Seçilen içeriğe yönlendirme
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions =
        searchResults
            .where(
              (element) => element.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }
}
