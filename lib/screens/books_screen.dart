// lib/screens/books_screen.dart

import 'package:flutter/material.dart';
import '../database/database_helper.dart'; // Book modelini ve DatabaseHelper'ı kullanmak için
import 'dart:io'; // Dosya işlemleri için (resim yolu kontrolü)
import 'book_detail_screen.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  List<Book> _books = []; // Tüm kitaplar
  List<Book> _filteredBooks = []; // Filtrelenmiş/Aranmış kitaplar
  final TextEditingController _searchController = TextEditingController();

 
  String _selectedReadingStatusFilter = 'Tümü';
  final List<String> _readingStatusFilters = [
    'Tümü',
    'Okundu',
    'Okunmadı',
  ];

  String _selectedSortBy = 'Son Eklenenler';
  final List<String> _sortOptions = [
    'Son Eklenenler',
    'Başlık (A-Z)',
    'Yazar (A-Z)',
    'Sayfa Sayısı (Artan)',
    'Sayfa Sayısı (Azalan)',
  ];

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _searchController.addListener(_filterBooks);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterBooks);
    _searchController.dispose();
    super.dispose();
  }

  // Kitapları veritabanından yükle
  Future<void> _loadBooks() async {
    try {
      final books = await DatabaseHelper.instance.getBooks();
      setState(() {
        _books = books;
        _filterBooks(); // Yüklendikten sonra filtrele ve sırala
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kitaplar yüklenirken bir hata oluştu: $e')),
        );
        print('Kitap yükleme hatası: $e');
      }
    }
  }

  // Kitapları filtrele ve sırala
  void _filterBooks() {
    List<Book> tempBooks = List.from(_books);

    // Arama filtresi
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      tempBooks = tempBooks.where((book) {
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query) ||
               book.publisher.toLowerCase().contains(query) ||
               book.tags.toLowerCase().contains(query); // Etiketlerde de arama
      }).toList();
    }

    // Okuma durumu filtresi
    if (_selectedReadingStatusFilter != 'Tümü') {
      tempBooks = tempBooks.where((book) => book.status == _selectedReadingStatusFilter).toList();
    }

    // Sıralama
    tempBooks.sort((a, b) {
      switch (_selectedSortBy) {
        case 'Başlık (A-Z)':
          return a.title.compareTo(b.title);
        case 'Yazar (A-Z)':
          return a.author.compareTo(b.author);
        case 'Sayfa Sayısı (Artan)':
          return a.pageCount.compareTo(b.pageCount);
        case 'Sayfa Sayısı (Azalan)':
          return b.pageCount.compareTo(a.pageCount);
        case 'Son Eklenenler':
        default:
          // ID'ye göre ters sıralama, son eklenenler için (eğer ID artıyorsa)
          return (b.id ?? 0).compareTo(a.id ?? 0);
      }
    });

    setState(() {
      _filteredBooks = tempBooks;
    });
  }


  // Kitap kartındaki kapak resmini oluşturan yardımcı metod
  Widget _buildBookCoverImage(String? path, {double size = 100}) {
    if (path == null || path.isEmpty) {
      return _buildDefaultImagePlaceholder(size: size);
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultImagePlaceholder(size: size);
        },
      );
    } else if (File(path).existsSync()) {
      return Image.file(
        File(path),
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultImagePlaceholder(size: size);
        },
      );
    } else if (path.startsWith('assets/')) {
       return Image.asset(
        path,
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultImagePlaceholder(size: size);
        },
      );
    }
    return _buildDefaultImagePlaceholder(size: size);
  }

  Widget _buildDefaultImagePlaceholder({double size = 100}) {
    return Container(
      height: size,
      width: size,
      color: Colors.grey[300],
      child: Icon(Icons.book, size: size * 0.6, color: Colors.grey[600]),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kitaplarım'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kitaplarda ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterBooks();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Durum filtresi
                DropdownButton<String>(
                  value: _selectedReadingStatusFilter,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedReadingStatusFilter = newValue!;
                      _filterBooks();
                    });
                  },
                  items: _readingStatusFilters.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                // Sıralama seçeneği
                DropdownButton<String>(
                  value: _selectedSortBy,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSortBy = newValue!;
                      _filterBooks();
                    });
                  },
                  items: _sortOptions.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
           Expanded(
            child: _filteredBooks.isEmpty
                ? const Center(child: Text('Henüz hiçbir kitap eklenmedi veya filtreye uygun kitap bulunamadı.'))
                : ListView.builder(
                    itemCount: _filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = _filteredBooks[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        child: InkWell(
                          // BURADAKİ DEĞİŞİKLİK: book detail ekranına yönlendir
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailScreen(book: book),
                              ),
                            );
                            if (result == true) {
                              _loadBooks(); // Detay ekranından dönüldüğünde listeyi yenile
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: _buildBookCoverImage(book.coverImagePath, size: 80),
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book.title,
                                        style: const TextStyle(
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        book.author,
                                        style: TextStyle(
                                          fontSize: 15.0,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4.0),
                                      if (book.publisher.isNotEmpty)
                                        Text(
                                          book.publisher,
                                          style: TextStyle(
                                            fontSize: 13.0,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 4.0),
                                      Row(
                                        children: [
                                          Icon(
                                            book.status == 'Okundu' ? Icons.check_circle : Icons.timer,
                                            size: 16,
                                            color: book.status == 'Okundu' ? Colors.green : Colors.orange,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            book.status,
                                            style: TextStyle(
                                              fontSize: 13.0,
                                              color: book.status == 'Okundu' ? Colors.green : Colors.orange,
                                            ),
                                          ),
                                          if (book.pageCount > 0) ...[
                                            const SizedBox(width: 12),
                                            Icon(Icons.menu_book, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${book.pageCount} sayfa',
                                              style: TextStyle(fontSize: 13.0, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // Kaldırılan FloatingActionButton:
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _navigateToBarcodeScanner, // Barkod tarayıcı ile kitap ekle
      //   label: const Text('Barkod Tara'),
      //   icon: const Icon(Icons.qr_code_scanner),
      // ),
    );
  }
}