// lib/screens/lists_screen.dart

import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'list_detail_screen.dart'; // Liste detay ekranı

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  List<BookList> _bookLists = [];
  Map<int, int> _bookCounts = {}; // Liste ID'sine göre kitap sayılarını tutar

  @override
  void initState() {
    super.initState();
    _loadBookLists();
  }

  Future<void> _loadBookLists() async {
    final lists = await DatabaseHelper.instance.getBookLists();
    final Map<int, int> counts = {};
    for (var list in lists) {
      if (list.id != null) {
        counts[list.id!] = await DatabaseHelper.instance.getBookCountInList(list.id!);
      }
    }
    setState(() {
      _bookLists = lists;
      _bookCounts = counts;
    });
  }

  // Liste oluşturma/düzenleme metodu (açıklama alanı kaldırıldı)
  Future<void> _addOrEditList({BookList? bookList}) async {
    TextEditingController nameController = TextEditingController(text: bookList?.name);
    bool isEditing = bookList != null;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'Listeyi Düzenle' : 'Yeni Liste Oluştur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Liste Adı'),
                ),
                // Açıklama alanı kaldırıldı
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(isEditing ? 'Kaydet' : 'Oluştur'),
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Liste adı boş olamaz!')),
                  );
                  return;
                }
                final newBookList = BookList(
                  id: bookList?.id,
                  name: nameController.text,
                  description: null, // Açıklama her zaman null olarak kaydedilecek
                );

                try {
                  if (isEditing) {
                    await DatabaseHelper.instance.updateBookList(newBookList);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Liste başarıyla güncellendi!')),
                      );
                    }
                  } else {
                    await DatabaseHelper.instance.insertBookList(newBookList);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Liste başarıyla oluşturuldu!')),
                      );
                    }
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                    _loadBookLists(); // Listeleri yenile
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Hata: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Silme metodu olduğu gibi kalacak, çünkü bu işlev ListDetailScreen'e taşınacak.
  // Ancak bu metodu artık ListsScreen'deki ListTile'dan çağırmayacağız.
  void _confirmDeleteList(BookList bookList) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Listeyi Sil'),
          content: Text('${bookList.name} adlı listeyi silmek istediğinizden emin misiniz? Bu işlem, listedeki kitapları silmez, sadece listeyi siler.'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                if (bookList.id != null) {
                  await DatabaseHelper.instance.deleteBookList(bookList.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Liste başarıyla silindi!')),
                    );
                    Navigator.of(context).pop();
                    _loadBookLists(); // Listeleri yenile
                  }
                }
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitap Listelerim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addOrEditList(), // Yeni liste oluştur
            tooltip: 'Yeni Liste Oluştur',
          ),
        ],
      ),
      body: _bookLists.isEmpty
          ? Center(
              child: Text(
                'Henüz hiçbir liste oluşturmadınız.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _bookLists.length,
              itemBuilder: (context, index) {
                final list = _bookLists[index];
                final bookCount = _bookCounts[list.id] ?? 0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: ListTile(
                    leading: const Icon(Icons.folder_shared, size: 40, color: Colors.blueGrey),
                    title: Text(
                      list.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      '${bookCount} kitap', // Açıklama kısmı kaldırıldı
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    // Düzenleme ve silme butonları buradan kaldırıldı
                    onTap: () {
                      if (list.id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListDetailScreen(bookList: list),
                          ),
                        ).then((value) => _loadBookLists()); // Detaydan dönünce listeleri yenile
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}