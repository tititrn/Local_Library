// lib/screens/book_detail_screen.dart

import 'package:flutter/material.dart';
import 'dart:io'; // Dosya işlemleri için
import '../database/database_helper.dart'; // Book modeli ve DatabaseHelper için
import 'book_form_screen.dart'; // Kitap düzenleme ekranı için

class BookDetailScreen extends StatefulWidget {
  final Book book; // Detaylarını göstereceğimiz kitap

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Book _currentBook; // Kitabın güncel halini tutmak için
  List<BookList> _allBookLists = []; // Tüm kitap listelerini tutar
  Set<int> _bookInLists = {}; // Bu kitabın hangi listelerde olduğunu tutar (liste ID'leri)

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book; // Başlangıçta widget'tan gelen kitabı ata
    _loadBookListsAndBookStatus(); // Listeleri ve kitabın liste durumunu yükle
  }

  Future<void> _loadBookListsAndBookStatus() async {
    final lists = await DatabaseHelper.instance.getBookLists();
    final listIdsForBook = _currentBook.id != null
        ? await DatabaseHelper.instance.getBookListIdsForBook(_currentBook.id!)
        : <int>[]; // Eğer kitap yeni ise listelerde olmaz

    setState(() {
      _allBookLists = lists;
      _bookInLists = listIdsForBook.toSet();
    });
  }

  // Kitabı düzenleme ekranına git
  void _navigateToEditBook() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookFormScreen(book: _currentBook),
      ),
    );

    // Eğer düzenleme başarılı olursa ve kitap güncellenirse
    if (result == true) {
      // Kitabı veritabanından tekrar yükleyerek güncel verileri al
      final updatedBook = await DatabaseHelper.instance.getBookById(_currentBook.id!);
      if (updatedBook != null) {
        setState(() {
          _currentBook = updatedBook; // Güncel kitabı state'e kaydet
        });
        // Ayrıca listelerin durumunu da yeniden yükle
        _loadBookListsAndBookStatus();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kitap başarıyla güncellendi!')),
          );
        }
      }
    }
  }

  // Kitabı silme onayı
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kitabı Sil'),
          content: Text('${_currentBook.title} adlı kitabı silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop(); // Diyalogu kapat
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(); // Diyalogu kapat
                _deleteBook(); // Silme işlemini başlat
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  // Kitabı silme
  Future<void> _deleteBook() async {
    if (_currentBook.id != null) {
      try {
        await DatabaseHelper.instance.deleteBook(_currentBook.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kitap başarıyla silindi!')),
          );
          Navigator.pop(context, true); // Kitap silindiğini BooksScreen'e bildirmek için true döndür
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kitap silinirken hata oluştu: $e')),
          );
        }
      }
    }
  }

  // Listeye Kitap Ekle/Çıkar işlevi için BottomSheet göster
  void _showAddToListBottomSheet() {
    if (_currentBook.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu kitap henüz kaydedilmediği için listeye eklenemez.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateBtmSheet) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Listelerime Ekle/Çıkar',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16.0),
                  if (_allBookLists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Text('Henüz hiç liste oluşturmadınız.'),
                      ),
                    )
                  else
                    Expanded( // Expanded ekledik ki ListView sığabilsin
                      child: ListView.builder(
                        shrinkWrap: true, // Listeyi içeriğine göre küçült
                        itemCount: _allBookLists.length,
                        itemBuilder: (context, index) {
                          final list = _allBookLists[index];
                          final bool isInList = _bookInLists.contains(list.id);
                          return CheckboxListTile(
                            title: Text(list.name),
                            value: isInList,
                            onChanged: (bool? value) async {
                              setStateBtmSheet(() { // BottomSheet state'ini güncelle
                                if (value == true) {
                                  _bookInLists.add(list.id!);
                                } else {
                                  _bookInLists.remove(list.id!);
                                }
                              });
                              // Veritabanı işlemini yap
                              if (value == true) {
                                await DatabaseHelper.instance.addBookToBookList(list.id!, _currentBook.id!);
                              } else {
                                await DatabaseHelper.instance.removeBookFromBookList(list.id!, _currentBook.id!);
                              }
                              if (mounted) {
                                // Ana ekranın da güncellenmesi için state'i yeniden yükle
                                setState(() {
                                  // Bu set state sadece _bookInLists'i günceller,
                                  // _loadBookListsAndBookStatus() daha kapsamlıdır.
                                });
                              }
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Yeni Liste Oluştur'),
                      onPressed: () {
                        Navigator.pop(context); // BottomSheet'i kapat
                        // Yeni liste oluşturma diyalogunu aç (ListsScreen'deki gibi)
                        _addOrEditNewListFromDetailScreen();
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
  }

  // BookDetailScreen'den yeni liste oluşturma diyalogu
  Future<void> _addOrEditNewListFromDetailScreen({BookList? bookList}) async {
    TextEditingController nameController = TextEditingController(text: bookList?.name);
    // Açıklama alanı kaldırıldığı için descriptionController artık kullanılmıyor.
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
                _showAddToListBottomSheet(); // Diyalog kapanınca BottomSheet'i tekrar aç
              },
            ),
            ElevatedButton(
              child: Text(isEditing ? 'Kaydet' : 'Oluştur'),
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Liste adı boş olamaz!')),
                    );
                  }
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
                    _loadBookListsAndBookStatus(); // Listeleri yenile ve kitabın durumunu güncelle
                    _showAddToListBottomSheet(); // Diyalog kapanınca BottomSheet'i tekrar aç
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

  String _getImagePathForBook(Book book) {
    if (book.coverImagePath != null && book.coverImagePath!.isNotEmpty) {
      if (book.coverImagePath!.startsWith('http://') || book.coverImagePath!.startsWith('https://')) {
        return book.coverImagePath!;
      }
      else if (File(book.coverImagePath!).existsSync()) {
        return book.coverImagePath!;
      }
    }
    return 'assets/images/default_book_cover.png'; // Varsayılan resim
  }

  Widget _buildBookCoverImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.contain, // Resmin boyutuna göre küçült, orantıyı koru
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
        },
      );
    }
    else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.contain, // Resmin boyutuna göre küçült, orantıyı koru
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
        },
      );
    }
    else if (File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.contain, // Resmin boyutuna göre küçült, orantıyı koru
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
        },
      );
    }
    else {
      return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayImagePath = _getImagePathForBook(_currentBook);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentBook.title),
        actions: [
          // Listeye Ekle ikonu
          IconButton(
            icon: const Icon(Icons.add_box),
            onPressed: _showAddToListBottomSheet, // BottomSheet'i açan metod
            tooltip: 'Listeye Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditBook,
            tooltip: 'Kitabı Düzenle',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
            tooltip: 'Kitabı Sil',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Kapak Resmi
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 200, // Resmin genişliği
                  height: 250, // Resmin yüksekliği
                  color: Colors.grey[200], // Resim yüklenmezse arkaplan rengi
                  child: _buildBookCoverImage(displayImagePath),
                ),
              ),
            ),
            const SizedBox(height: 24.0),

            // Kitap Başlığı
            Text(
              _currentBook.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),

            // Yazar
            Text(
              _currentBook.author,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16.0),

            // Detaylar (Yayınevi, Konum, Sayfa Sayısı)
            ListTile(
              leading: const Icon(Icons.business),
              title: const Text('Yayınevi'),
              subtitle: Text(_currentBook.publisher.isNotEmpty ? _currentBook.publisher : 'Belirtilmemiş'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Konum'),
              subtitle: Text(_currentBook.location.isNotEmpty ? _currentBook.location : 'Belirtilmemiş'),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book),
              title: const Text('Sayfa Sayısı'),
              subtitle: Text(_currentBook.pageCount > 0 ? _currentBook.pageCount.toString() : 'Belirtilmemiş'),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_added),
              title: const Text('Okuma Durumu'),
              subtitle: Text(
                _currentBook.status,
                style: TextStyle(
                  color: _currentBook.status == 'Okundu' ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_currentBook.tags.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.label),
                title: const Text('Etiketler'),
                subtitle: Text(_currentBook.tags),
              ),
            const SizedBox(height: 16.0),

            // Açıklama
            Text(
              'Açıklama:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              _currentBook.description.isNotEmpty ? _currentBook.description : 'Açıklama bulunmuyor.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24.0),
          ],
        ),
      ),
    );
  }
}