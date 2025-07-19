// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'dart:io'; // File işlemleri için
import '../database/database_helper.dart'; // Book modelini ve DatabaseHelper'ı kullanmak için
import 'book_detail_screen.dart'; // Kitap detay ekranı (YENİ EKLENDİ)

class SearchScreen extends StatefulWidget {
  final List<Book> allBooks; // Tüm kitapları burada alacağız

  const SearchScreen({super.key, required this.allBooks});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Book> _searchResults = [];

  final String _defaultBookCoverPath = 'assets/images/default_book_cover.png'; // Varsayılan kapak yolu

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch);
    _searchResults = List.from(widget.allBooks); // Başlangıçta tüm kitapları göster
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _searchResults = widget.allBooks.where((book) {
        return book.title.toLowerCase().contains(query) ||
               book.author.toLowerCase().contains(query) ||
               book.publisher.toLowerCase().contains(query) ||
               book.location.toLowerCase().contains(query) ||
               book.description.toLowerCase().contains(query) || // Açıklamada da ara
               book.tags.toLowerCase().contains(query); // Etiketlerde de ara
      }).toList();
    });
  }

  // Kitap Detay Sayfasına git (YENİ METOT)
  Future<void> _navigateToBookDetail(Book book) async {
    final bool? bookDeleted = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
    );
    // Eğer kitap detay ekranından dönüldüğünde kitap silinmişse veya güncellenmişse arama sonuçlarını yenile
    if (bookDeleted == true || bookDeleted == false) {
      _performSearch();
    }
  }

  // Kitap durumuna göre renk döndürür (Home/Books ekranlarından kopyalandı, burada kullanılmasa da durmasında sakınca yok)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Okundu':
        return Colors.green;
      case 'Okunmadı':
      default:
        return Colors.grey;
    }
  }

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
  Widget _buildBookCoverImage(String path, {double size = 50}) {
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
  Widget _buildDefaultImagePlaceholder({double size = 50}) {
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
        title: TextField(
          controller: _searchController,
          autofocus: true, // Açıldığında klavyenin otomatik açılmasını sağlar
          decoration: InputDecoration(
            hintText: 'Kitap ara...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            ),
          ),
        ),
      ),
      body: _searchResults.isEmpty
          ? const Center(child: Text('Kitap bulunamadı.'))
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final book = _searchResults[index];
                final displayImagePath = _getImagePathForBook(book); // Kapak resmi yolu

                return Card( // Kart görünümü ekle
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: ListTile(
                    leading: ClipRRect( // Yuvarlak köşeli leading resim
                      borderRadius: BorderRadius.circular(8.0),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: _buildBookCoverImage(displayImagePath, size: 60), // Resmi göster
                      ),
                    ),
                    title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${book.author} - ${book.publisher}'),
                        Text('Konum: ${book.location}'),
                        Text(
                          'Durum: ${book.status}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(book.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (book.tags.isNotEmpty)
                          Text(
                            'Etiketler: ${book.tags}',
                            style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () => _navigateToBookDetail(book), // Detay ekranına yönlendir
                  ),
                );
              },
            ),
    );
  }
}