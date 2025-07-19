// lib/screens/list_detail_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import '../database/database_helper.dart';
import 'book_detail_screen.dart'; // Kitap detay ekranı

class ListDetailScreen extends StatefulWidget {
  final BookList bookList; // Detaylarını göstereceğimiz liste

  const ListDetailScreen({super.key, required this.bookList});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  late BookList _currentBookList; // Listenin güncel halini tutmak için
  List<Book> _booksInList = [];
  List<Book> _allAvailableBooks = []; // Listeye eklenecek tüm kitaplar
  List<Book> _filteredAvailableBooks = []; // Arama sonucunda filtrelenen kitaplar
  Set<int> _bookIdsInCurrentList = {}; // Mevcut listedeki kitap ID'lerini tutar

  final String _defaultBookCoverPath = 'assets/images/default_book_cover.png';

  final TextEditingController _searchController = TextEditingController(); // Arama çubuğu için controller

  @override
  void initState() {
    super.initState();
    _currentBookList = widget.bookList;
    _loadBooksAndListStatus();
    _searchController.addListener(_filterAvailableBooks); // Arama kutusu değiştiğinde filtrele
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAvailableBooks);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooksAndListStatus() async {
    if (_currentBookList.id != null) {
      final books = await DatabaseHelper.instance.getBooksInList(_currentBookList.id!);
      final allBooks = await DatabaseHelper.instance.getBooks(); // Tüm kitapları da al
      final bookIds = books.map((b) => b.id!).toSet();

      setState(() {
        _booksInList = books;
        _allAvailableBooks = allBooks;
        _bookIdsInCurrentList = bookIds;
        _filterAvailableBooks(); // Kitaplar yüklendiğinde bir kez filtrele
      });
    }
  }

  // Kitapları arama çubuğuna göre filtreleyen metod
  void _filterAvailableBooks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAvailableBooks = _allAvailableBooks.where((book) {
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _navigateToBookDetail(Book book) async {
    final bool? bookDeletedOrUpdated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
    );
    if (bookDeletedOrUpdated == true || bookDeletedOrUpdated == false) {
      _loadBooksAndListStatus(); // Kitap detay ekranından dönüldüğünde listeyi yenile
    }
  }

  void _removeBookFromList(int bookId) async {
    if (_currentBookList.id != null) {
      await DatabaseHelper.instance.removeBookFromBookList(_currentBookList.id!, bookId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kitap listeden çıkarıldı!')),
        );
        _loadBooksAndListStatus(); // Listeyi yenile
      }
    }
  }

  // Liste Adını Düzenleme Metodu
  Future<void> _editList() async {
    TextEditingController nameController = TextEditingController(text: _currentBookList.name);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Listeyi Düzenle'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Liste Adı'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Kaydet'),
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Liste adı boş olamaz!')),
                  );
                  return;
                }
                final updatedList = BookList(
                  id: _currentBookList.id,
                  name: nameController.text,
                  description: _currentBookList.description,
                );

                try {
                  await DatabaseHelper.instance.updateBookList(updatedList);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Liste başarıyla güncellendi!')),
                    );
                    Navigator.of(context).pop();
                    setState(() {
                      _currentBookList = updatedList; // UI'yı güncelle
                    });
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

  // Listeyi Silme Metodu
  void _confirmDeleteList() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Listeyi Sil'),
          content: Text('${_currentBookList.name} adlı listeyi silmek istediğinizden emin misiniz? Bu işlem, listedeki kitapları silmez, sadece listeyi siler.'),
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
                if (_currentBookList.id != null) {
                  await DatabaseHelper.instance.deleteBookList(_currentBookList.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Liste başarıyla silindi!')),
                    );
                    Navigator.of(context).pop(); // Diyalogu kapat
                    Navigator.of(context).pop(); // Liste ekranına geri dön
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

  // Bu listeye kitap eklemek için BottomSheet
  void _showAddBooksToThisListBottomSheet() {
    if (_currentBookList.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Liste kaydedilmediği için kitap eklenemez.')),
      );
      return;
    }

    // BottomSheet açıldığında arama çubuğunu temizle ve tüm kitapları göster
    _searchController.clear();
    _filterAvailableBooks();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Klavye açıldığında BottomSheet'in yukarı kaymasını sağlar
      builder: (BuildContext bc) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateBtmSheet) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Klavye boşluğu
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Kitapları Listeye Ekle',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16.0),
                    // Arama Çubuğu
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Kitap ara...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onChanged: (value) {
                        setStateBtmSheet(() {
                          _filterAvailableBooks(); // BottomSheet'in state'ini güncelle
                        });
                      },
                    ),
                    const SizedBox(height: 16.0),
                    // Listeye eklenebilecek tüm kitapları göster
                    // Mevcut listedeki kitaplar işaretli olsun
                    _filteredAvailableBooks.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(
                              child: Text('Kitap bulunamadı.'),
                            ),
                          )
                        : Expanded(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredAvailableBooks.length,
                              itemBuilder: (context, index) {
                                final book = _filteredAvailableBooks[index];
                                final bool isInList = _bookIdsInCurrentList.contains(book.id);

                                return CheckboxListTile(
                                  title: Text(book.title),
                                  subtitle: Text(book.author),
                                  value: isInList,
                                  onChanged: (bool? value) async {
                                    if (book.id == null) return; // Kitap ID'si yoksa işlem yapma

                                    setStateBtmSheet(() {
                                      if (value == true) {
                                        _bookIdsInCurrentList.add(book.id!);
                                      } else {
                                        _bookIdsInCurrentList.remove(book.id!);
                                      }
                                    });
                                    // Veritabanı işlemini yap
                                    if (value == true) {
                                      await DatabaseHelper.instance.addBookToBookList(_currentBookList.id!, book.id!);
                                    } else {
                                      await DatabaseHelper.instance.removeBookFromBookList(_currentBookList.id!, book.id!);
                                    }
                                    // Ana ekranın da güncellenmesi için listeleri yeniden yükle
                                    if (mounted) {
                                      _loadBooksAndListStatus();
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                    const SizedBox(height: 16.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // BottomSheet'i kapat
                        },
                        child: const Text('Tamam'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Resim gösterme yardımcı metotları
  String _getImagePathForBook(Book book) {
    if (book.coverImagePath != null && book.coverImagePath!.isNotEmpty) {
      if (book.coverImagePath!.startsWith('http://') || book.coverImagePath!.startsWith('https://')) {
        return book.coverImagePath!;
      }
      else if (File(book.coverImagePath!).existsSync()) {
        return book.coverImagePath!;
      }
    }
    return _defaultBookCoverPath;
  }

  Widget _buildBookCoverImage(String path, {double size = 100}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultImagePlaceholder(size: size);
        },
      );
    }
    else if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultImagePlaceholder(size: size);
        },
      );
    }
    else if (File(path).existsSync()) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultImagePlaceholder(size: size);
        },
      );
    }
    else {
      return _buildDefaultImagePlaceholder(size: size);
    }
  }

  Widget _buildDefaultImagePlaceholder({double size = 100}) {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.book,
          size: size * 0.6,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentBookList.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box), // Kitap ekle butonu
            onPressed: _showAddBooksToThisListBottomSheet,
            tooltip: 'Bu Listeye Kitap Ekle',
          ),
          IconButton(
            icon: const Icon(Icons.edit), // Listeyi düzenle butonu
            onPressed: _editList,
            tooltip: 'Listeyi Düzenle',
          ),
          IconButton(
            icon: const Icon(Icons.delete), // Listeyi sil butonu
            onPressed: _confirmDeleteList,
            tooltip: 'Listeyi Sil',
          ),
        ],
      ),
      body: _booksInList.isEmpty
          ? Center(
              child: Text(
                'Bu listede henüz kitap bulunmuyor.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _booksInList.length,
              itemBuilder: (context, index) {
                final book = _booksInList[index];
                final displayImagePath = _getImagePathForBook(book);

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: _buildBookCoverImage(displayImagePath, size: 100),
                      ),
                    ),
                    title: Text(
                      book.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.author,
                        ),
                        Text(
                          'Sayfa: ${book.pageCount}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () => _removeBookFromList(book.id!),
                      tooltip: 'Listeden Çıkar',
                    ),
                    onTap: () => _navigateToBookDetail(book),
                  ),
                );
              },
            ),
    );
  }
}