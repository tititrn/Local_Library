// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';

// Book modeli artık database_helper.dart içinden geliyor
import '../database/database_helper.dart';

// Diğer ekran importları
import 'book_form_screen.dart'; // Add ve Edit işlemleri için tek dosya
import 'barcode_scanner_screen.dart';
import 'search_screen.dart';
import 'book_detail_screen.dart'; // Kitap detay ekranı için eklendi

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> _books = [];
  List<Book> _carouselBooks = []; // Carousel için okunmamış son 10 kitap

  int _totalBooks = 0;
  int _currentCarouselIndex = 0; // Bu hala carousel'in nokta göstergesi için kalmalı

  // Kitap kapakları için varsayılan yol
  final String _defaultBookCoverPath = 'assets/images/default_book_cover.png';

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadBooks() async {
    final books = await DatabaseHelper.instance.getBooks();
    setState(() {
      _books = books;
      _updateStatusCounts(books);

      _carouselBooks = books
          .where((book) => book.status != 'Okundu')
          .toList();
      _carouselBooks.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      if (_carouselBooks.length > 10) {
        _carouselBooks = _carouselBooks.sublist(0, 10);
      }
    });
  }

  void _updateStatusCounts(List<Book> books) {
    _totalBooks = books.length;
  }

  Future<void> _navigateToAddBook() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookFormScreen()),
    );
    if (result == true) {
      _loadBooks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kitap başarıyla eklendi!')),
        );
      }
    }
  }

  // BookDetailScreen'e gidecek metot
  Future<void> _navigateToBookDetail(Book book) async {
    final bool? bookDeleted = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
    );
    // Eğer kitap detay ekranından dönüldüğünde kitap silinmişse veya güncellenmişse listeyi yenile
    if (bookDeleted == true || bookDeleted == false) { // false da döndürebilir güncellemede
      _loadBooks();
    }
  }


  Future<void> _navigateToBarcodeScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (result == true) {
      _loadBooks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kitap başarıyla eklendi!')),
        );
      }
    }
  }

  // Bu metodun artık doğrudan kullanılmaması gerekiyor, BookDetailScreen üzerinden yapılacak
  // Future<void> _deleteBook(int id) async {
  //   await DatabaseHelper.instance.deleteBook(id);
  //   _loadBooks();
  // }

  // Kitap kapak yolunu döner (varsayılan resim dahil)
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

  // Kitap kapak resmini oluşturur
  Widget _buildBookCoverImage(String path, {double size = 150}) {
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

  // Varsayılan resim yer tutucusu
  Widget _buildDefaultImagePlaceholder({double size = 150}) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 56) / 4; // 16*2 padding + 8*3 spacing
    final itemHeight = itemWidth * 1.5;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kişisel Kütüphanem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchScreen(allBooks: _books),
                ),
              ).then((_) => _loadBooks());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: _buildStatusChip('Toplam Kitap', _totalBooks),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                'Okunmayı Bekleyenler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _carouselBooks.isNotEmpty
                ? CarouselSlider.builder(
                    itemCount: _carouselBooks.length,
                    itemBuilder: (BuildContext context, int itemIndex, int pageViewIndex) {
                      final book = _carouselBooks[itemIndex];
                      final displayImagePath = _getImagePathForBook(book);

                      return GestureDetector(
                        onTap: () {
                          _navigateToBookDetail(book); // Kitap detay ekranına yönlendir
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8.0),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4.0,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: _buildBookCoverImage(displayImagePath),
                          ),
                        ),
                      );
                    },
                    options: CarouselOptions(
                      height: 250.0,
                      enlargeCenterPage: true,
                      autoPlay: true,
                      aspectRatio: 16 / 9,
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enableInfiniteScroll: true,
                      autoPlayAnimationDuration: const Duration(milliseconds: 800),
                      viewportFraction: 0.8,
                      onPageChanged: (index, reason) {
                        setState(() {
                          _currentCarouselIndex = index;
                        });
                      },
                    ),
                  )
                : const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Henüz okunmamış kitap yok. Hadi bir kitap ekleyelim!',
                        style: TextStyle(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

            if (_carouselBooks.isNotEmpty) // Sadece carousel varsa noktaları göster
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _carouselBooks.asMap().entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      // CarouselController kullanmadığımız için burada herhangi bir işlem yapmaya gerek yok
                      // İsterseniz manuel olarak sayfa değiştiren bir fonksiyon ekleyebilirsiniz.
                    },
                    child: Container(
                      width: 10.0,
                      height: 10.0,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black).withAlpha((255 * (_currentCarouselIndex == entry.key ? 0.9 : 0.4)).round()),
                      ),
                    ),
                  );
                }).toList(),
              ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Hazinem',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _books.map((book) {
                  final displayImagePath = _getImagePathForBook(book);
                  return GestureDetector(
                    onTap: () {
                      _navigateToBookDetail(book); // Kitap detay ekranına yönlendir
                    },
                    child: SizedBox(
                      width: itemWidth,
                      height: itemHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.0),
                        child: _buildBookCoverImage(displayImagePath, size: itemHeight),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Manuel Kitap Ekle'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToAddBook();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.qr_code_scanner),
                    title: const Text('Barkod ile Kitap Ekle'),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToBarcodeScanner();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count) {
    return Chip(
      label: Text(
        '$label: $count',
        style: const TextStyle(color: Colors.black),
      ),
      backgroundColor: Colors.amber[200],
    );
  }
}