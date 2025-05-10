import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeakademix/profile_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:projeakademix/login_page.dart';
import 'package:projeakademix/edit_profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.firstName, required this.lastName})
    : super(key: key);

  final String firstName;
  final String lastName;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          "Ana Sayfa",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade800,
        actions: [
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
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue.shade800),
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
              leading: Icon(Icons.edit),
              title: Text('Profili Düzenle'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => EditProfilePage(
                          firstName: widget.firstName,
                          lastName: widget.lastName,
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade100.withOpacity(0.5),
              Colors.blue.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),
            // Öne Çıkanlar Bölümü
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Öne Çıkanlar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
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
                            final fileType =
                                item['fileName']?.split('.').last ?? 'Dosya';
                            final icon =
                                fileType == 'pdf'
                                    ? Icons.picture_as_pdf
                                    : fileType == 'docx'
                                    ? Icons.description
                                    : Icons.insert_drive_file;
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              margin: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Container(
                                width: 200,
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 40,
                                      color: Colors.blue.shade800,
                                    ),
                                    SizedBox(height: 5),
                                    Flexible(
                                      child: Text(
                                        item['fileName'] ?? 'Başlık yok',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Flexible(
                                      child: Text(
                                        "Tarih: ${item['timestamp']?.toDate().toString() ?? 'Tarih yok'}",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      fileType.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade600,
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
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color:
                            selectedIndex == index
                                ? Colors.blue.shade800
                                : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (selectedIndex == index)
                            BoxShadow(
                              color: Colors.blue.shade200,
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          categories[index],
                          style: TextStyle(
                            color:
                                selectedIndex == index
                                    ? Colors.white
                                    : Colors.black,
                            fontWeight: FontWeight.bold,
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
                              userSnapshot.data!.data()
                                  as Map<String, dynamic>?;
                          final userEmail = userData?['email'] ?? 'Bilinmiyor';
                          return Card(
                            margin: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            child: ListTile(
                              leading: Icon(
                                selectedIndex == 1
                                    ? Icons.announcement
                                    : Icons.file_present,
                                color: Colors.blue.shade800,
                              ),
                              title: Text(
                                selectedIndex == 1
                                    ? item['title'] ?? 'Başlık yok'
                                    : item['fileName'] ?? 'Dosya adı yok',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                selectedIndex == 1
                                    ? "${item['description'] ?? 'Açıklama yok'}\nE-posta: $userEmail\nTarih: ${item['timestamp']?.toDate().toString() ?? 'Tarih yok'}"
                                    : "Yükleme Tarihi: ${item['timestamp']?.toDate().toString() ?? 'Tarih yok'}\nE-posta: $userEmail",
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => FullScreenContentPage(
                                          item: item,
                                          selectedIndex: selectedIndex,
                                        ),
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

class FullScreenContentPage extends StatelessWidget {
  final QueryDocumentSnapshot item;
  final int selectedIndex;

  const FullScreenContentPage({
    Key? key,
    required this.item,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final commentsCollection = FirebaseFirestore.instance
        .collection(selectedIndex == 1 ? 'ilanlar' : 'ders_notlari')
        .doc(item.id)
        .collection('comments');

    TextEditingController commentController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedIndex == 1
              ? item['title'] ?? 'Başlık yok'
              : item['fileName'] ?? 'Dosya adı yok',
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedIndex == 1)
                Text("Açıklama: ${item['description'] ?? 'Açıklama yok'}"),
              Text("E-posta: ${user?.email ?? 'Bilinmiyor'}"),
              Text(
                "Tarih: ${item['timestamp']?.toDate().toString() ?? 'Tarih yok'}",
              ),
              if (selectedIndex != 1)
                TextButton.icon(
                  onPressed: () async {
                    try {
                      final url = item['fileUrl'];
                      if (url != null && url.isNotEmpty) {
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Dosya URL'si açılamıyor.")),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Dosya URL'si bulunamadı.")),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Hata: $e")));
                    }
                  },
                  icon: Icon(Icons.download),
                  label: Text("Dosyayı İndir"),
                ),
              SizedBox(height: 20),
              StreamBuilder<DocumentSnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection(
                          selectedIndex == 1 ? 'ilanlar' : 'ders_notlari',
                        )
                        .doc(item.id)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text("Hata: ${snapshot.error}");
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.thumb_up_outlined),
                          onPressed: () async {
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Giriş yapmanız gerekiyor."),
                                ),
                              );
                              return;
                            }
                            await FirebaseFirestore.instance
                                .collection(
                                  selectedIndex == 1
                                      ? 'ilanlar'
                                      : 'ders_notlari',
                                )
                                .doc(item.id)
                                .set({
                                  'likeCount': 1,
                                  'likes': {user.uid: true},
                                }, SetOptions(merge: true));
                          },
                        ),
                        Text("0 Beğeni"),
                      ],
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final likeCount = data['likeCount'] ?? 0;
                  final likes = data['likes'] ?? {};
                  final isLiked = likes[user?.uid] == true;

                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: isLiked ? Colors.blue : null,
                        ),
                        onPressed: () async {
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Giriş yapmanız gerekiyor."),
                              ),
                            );
                            return;
                          }
                          final docRef = FirebaseFirestore.instance
                              .collection(
                                selectedIndex == 1 ? 'ilanlar' : 'ders_notlari',
                              )
                              .doc(item.id);

                          if (isLiked) {
                            await docRef.update({
                              'likeCount': FieldValue.increment(-1),
                              'likes.${user.uid}': FieldValue.delete(),
                            });
                          } else {
                            await docRef.update({
                              'likeCount': FieldValue.increment(1),
                              'likes.${user.uid}': true,
                            });
                          }
                        },
                      ),
                      Text("$likeCount Beğeni"),
                    ],
                  );
                },
              ),
              SizedBox(height: 20),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  labelText: "Yorum Yap",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final comment = commentController.text;
                    if (comment.isNotEmpty && user != null) {
                      // Fetch the user's displayName from Firestore
                      final userDoc =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .get();
                      final userName =
                          userDoc.data()?['displayName'] ??
                          user.email ??
                          'Bilinmiyor';

                      await commentsCollection.add({
                        'userId': user.uid,
                        'author':
                            userName, // Use the fetched displayName or fallback to email
                        'content': comment,
                        'timestamp': Timestamp.now(),
                      });
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Yorum eklendi!")));
                      commentController.clear();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Yorum boş olamaz veya giriş yapmanız gerekiyor.",
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Hata: $e")));
                  }
                },
                child: Text("Yorumu Gönder"),
              ),
              SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream:
                    commentsCollection
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text("Hata: ${snapshot.error}");
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Text("Henüz yorum yapılmamış.");
                  }
                  final comments = snapshot.data!.docs;
                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          title: Text(comment['content'] ?? ""),
                          subtitle: Text(
                            "Yazan: ${comment['author'] ?? "Bilinmiyor"}",
                          ), // Provide default value for 'author'
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
