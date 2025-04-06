import 'package:flutter/material.dart';
import 'package:projeakademix/edit_profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeakademix/profile_page.dart';

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

  final List<String> categories = [
    'Ders Notları',
    'Çıkmış Sorular',
    'Ders İlanları',
  ];

  final List<Map<String, dynamic>> contentList = [
    {
      'title': 'Ders Notu 1',
      'description': 'Matematik notları',
      'category': 'Ders Notları',
      'likes': 120,
      'date': DateTime.now().subtract(Duration(days: 1)),
    },
    {
      'title': 'Çıkmış Soru 1',
      'description': 'Fizik 2022 çıkmış sorular',
      'category': 'Çıkmış Sorular',
      'likes': 95,
      'date': DateTime.now().subtract(Duration(days: 2)),
    },
    {
      'title': 'Ders İlanı 1',
      'description': 'Özel ders: Kimya',
      'category': 'Ders İlanları',
      'likes': 150,
      'date': DateTime.now().subtract(Duration(hours: 5)),
    },
    {
      'title': 'Ders Notu 2',
      'description': 'Kimya notları',
      'category': 'Ders Notları',
      'likes': 80,
      'date': DateTime.now().subtract(Duration(days: 3)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Öne çıkan içerikleri belirle (en çok beğeni alanlar)
    final featuredContent =
        contentList.where((content) => content['likes'] > 100).toList()
          ..sort((a, b) => b['likes'].compareTo(a['likes']));

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
                Container(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: featuredContent.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          width: 200,
                          padding: EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                featuredContent[index]['title'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                featuredContent[index]['description'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Spacer(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.thumb_up, size: 16),
                                  Text('${featuredContent[index]['likes']}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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
            child: ListView.builder(
              itemCount: contentList.length,
              itemBuilder: (context, index) {
                if (contentList[index]['category'] !=
                    categories[selectedIndex]) {
                  return SizedBox.shrink();
                }
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    leading: Icon(Icons.article),
                    title: Text(contentList[index]['title']!),
                    subtitle: Text(contentList[index]['description']!),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.thumb_up),
                          onPressed: () {
                            // Beğeni işlemi
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.comment),
                          onPressed: () {
                            // Yorum işlemi
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      // İçerik detayına yönlendirme
                    },
                  ),
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
