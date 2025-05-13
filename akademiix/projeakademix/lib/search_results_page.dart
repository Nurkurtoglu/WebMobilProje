import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class SearchResultsPage extends StatelessWidget {
  final String query;

  const SearchResultsPage({Key? key, required this.query}) : super(key: key);

  Stream<List<List<DocumentSnapshot>>> getCombinedSearchResults(String query) {
    final lowerCaseQuery = query.toLowerCase();

    final dersNotlariStream =
        FirebaseFirestore.instance.collection('ders_notlari').snapshots();

    final ilanlarStream =
        FirebaseFirestore.instance.collection('ilanlar').snapshots();

    return StreamZip([dersNotlariStream, ilanlarStream]).map((snapshots) {
      final dersNotlariResults =
          snapshots[0].docs.where((doc) {
            final fileName = doc['fileName'].toString().toLowerCase();
            return fileName.contains(lowerCaseQuery);
          }).toList();

      final ilanlarResults =
          snapshots[1].docs.where((doc) {
            final title = doc['title'].toString().toLowerCase();
            return title.contains(lowerCaseQuery);
          }).toList();

      return [dersNotlariResults, ilanlarResults];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arama Sonuçları'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(), // Removed the search button and TextField
          ),
          Expanded(
            child: StreamBuilder<List<List<DocumentSnapshot>>>(
              stream: getCombinedSearchResults(query),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Bir hata oluştu: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData ||
                    snapshot.data!.every((snap) => snap.isEmpty)) {
                  return Center(child: Text('Sonuç bulunamadı.'));
                }

                final dersNotlariResults = snapshot.data![0];
                final ilanlarResults = snapshot.data![1];

                final combinedResults = [
                  ...dersNotlariResults,
                  ...ilanlarResults,
                ];

                return ListView.builder(
                  itemCount: combinedResults.length,
                  itemBuilder: (context, index) {
                    final item = combinedResults[index];
                    final isDersNotu = index < dersNotlariResults.length;

                    return ListTile(
                      title: Text(
                        isDersNotu ? item['fileName'] : item['title'],
                      ),
                      subtitle: Text(isDersNotu ? 'Ders Notu' : 'İlan'),
                      trailing:
                          isDersNotu
                              ? null
                              : ElevatedButton(
                                onPressed: () async {
                                  final currentUser =
                                      FirebaseAuth.instance.currentUser;
                                  if (currentUser != null) {
                                    await FirebaseFirestore.instance
                                        .collection('notifications')
                                        .add({
                                          'senderId': currentUser.uid,
                                          'receiverId': item['userId'],
                                          'type': 'lesson_request',
                                          'status': 'pending',
                                          'timestamp':
                                              FieldValue.serverTimestamp(),
                                        });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Özel ders isteği gönderildi.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text('İstek Gönder'),
                              ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => FullScreenContentPage(
                                  item: item,
                                  selectedIndex: isDersNotu ? 0 : 1,
                                ),
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
    );
  }
}

class FullScreenContentPage extends StatelessWidget {
  final DocumentSnapshot item;
  final int selectedIndex;

  const FullScreenContentPage({
    Key? key,
    required this.item,
    required this.selectedIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Oluşturan: ${item['userEmail'] ?? 'Bilinmiyor'}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              if (selectedIndex == 1)
                Text("Açıklama: ${item['description'] ?? 'Açıklama yok'}"),
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
                            final user = FirebaseAuth.instance.currentUser;
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
                  final user = FirebaseAuth.instance.currentUser;
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
                    final user = FirebaseAuth.instance.currentUser;
                    if (comment.isNotEmpty && user != null) {
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
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final DocumentSnapshot notification;

  const NotificationCard({Key? key, required this.notification})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Bir kullanıcı ilanınıza özel ders isteği gönderdi.'),
        subtitle: Text('Gönderen: ${notification['senderEmail']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(notification.id)
                    .update({'status': 'accepted'});

                await FirebaseFirestore.instance.collection('notifications').add({
                  'senderId': FirebaseAuth.instance.currentUser?.uid,
                  'receiverId': notification['senderId'],
                  'type': 'response',
                  'status': 'accepted',
                  'message':
                      'Kullanıcı ${FirebaseAuth.instance.currentUser?.email} adresinden iletişime geçebilirsiniz.',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('İstek kabul edildi.')));
              },
              child: Text('Kabul Et'),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(notification.id)
                    .update({'status': 'rejected'});

                await FirebaseFirestore.instance
                    .collection('notifications')
                    .add({
                      'senderId': FirebaseAuth.instance.currentUser?.uid,
                      'receiverId': notification['senderId'],
                      'type': 'response',
                      'status': 'rejected',
                      'message': 'Maalesef isteğiniz reddedildi.',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('İstek reddedildi.')));
              },
              child: Text('Reddet'),
            ),
          ],
        ),
      ),
    );
  }
}
