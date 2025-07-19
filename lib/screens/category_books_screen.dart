// lib/screens/category_books_screen.dart

import 'package:flutter/material.dart';
import 'dart:io'; // File işlemleri için
import '../database/database_helper.dart'; // Book modelini ve DatabaseHelper'ı kullanmak için
import 'book_detail_screen.dart'; // Kitap detay ekranı için

class CategoryBooksScreen extends StatefulWidget {
  final String categoryName; // Gösterilecek kategori adı

  const CategoryBooksScreen({super.key, required this.categoryName});

  @override
  State<CategoryBooksScreen> createState() => _CategoryBooksScreenState();
}

class _CategoryBooksScreenState extends State<CategoryBooksScreen> {
  List<Book> _categoryBooks = [];
  final String _defaultBookCoverPath = 'assets/images/default_book_cover.png';

  @override
  void initState() {
    super.initState();
    _loadBooksByCategory(); // Kategorideki kitapları yükle
  }

  Future<void> _loadBooksByCategory() async {
    final allBooks = await DatabaseHelper.instance.getBooks();
    final filteredBooks = allBooks.where((book) {
      // Kitabın etiketleri arasında kategori adı var mı kontrol et
      return book.tags.split(',').map((e) => e.trim()).contains(widget.categoryName);
    }).toList();

    setState(() {
      _categoryBooks = filteredBooks;
    });
  }

  void _navigateToBookDetail(Book book) async {
    // Detay ekranından dönüldüğünde liste güncellenebilir (silme/düzenleme sonrası)
    final bool? bookDeletedOrUpdated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
    );
    if (bookDeletedOrUpdated == true || bookDeletedOrUpdated == false) {
      _loadBooksByCategory(); // Kitapları yeniden yükle
    }
  }

  // Resim gösterme yardımcı metotları (BooksScreen'den kopyalanabilir)
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
        title: Text('${widget.categoryName} Kitapları'),
      ),
      body: _categoryBooks.isEmpty
          ? Center(
              child: Text(
                'Bu kategoride henüz kitap bulunmuyor.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              itemCount: _categoryBooks.length,
              itemBuilder: (context, index) {
                final book = _categoryBooks[index];
                final displayImagePath = _getImagePathForBook(book);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          'Durum: ${book.status}',
                          style: TextStyle(
                            fontSize: 14,
                            color: book.status == 'Okundu' ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: false,
                    onTap: () => _navigateToBookDetail(book),
                  ),
                );
              },
            ),
    );
  }
}