// lib/database/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart'; // Veritabanı yolunu birleştirmek için

// Kitap Modelimiz (Mevcut)
class Book {
  int? id;
  String title;
  String author;
  String publisher;
  String location;
  int pageCount;
  String description;
  String? coverImagePath; // Kapak resmi yolu (null olabilir)
  String status; // Okuma durumu (Okundu, Okunmadı vb.)
  String tags; // Etiketler (virgülle ayrılmış string)

  Book({
    this.id,
    required this.title,
    required this.author,
    this.publisher = '',
    this.location = '',
    this.pageCount = 0,
    this.description = '',
    this.coverImagePath,
    this.status = 'Okunmadı',
    this.tags = '',
  });

  // Book objesini Map'e dönüştürür (veritabanına kaydetmek için)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'publisher': publisher,
      'location': location,
      'pageCount': pageCount,
      'description': description,
      'coverImagePath': coverImagePath,
      'status': status,
      'tags': tags,
    };
  }

  // Map'ten Book objesi oluşturur (veritabanından okumak için)
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String,
      publisher: map['publisher'] as String,
      location: map['location'] as String,
      pageCount: map['pageCount'] as int,
      description: map['description'] as String,
      coverImagePath: map['coverImagePath'] as String?,
      status: map['status'] as String,
      tags: map['tags'] as String,
    );
  }
}

// Yeni: Kitap Listesi Modeli
class BookList {
  int? id;
  String name;
  String? description; // Liste açıklaması

  BookList({
    this.id,
    required this.name,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  factory BookList.fromMap(Map<String, dynamic> map) {
    return BookList(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'book_library.db');
    return await openDatabase(
      path,
      version: 2, // Veritabanı versiyonunu artırdık (tablo eklediğimiz için)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Yeni onUpgrade metodu eklendi
    );
  }

  // İlk veritabanı oluşturulduğunda çalışır (versiyon 1)
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        publisher TEXT NOT NULL,
        location TEXT NOT NULL,
        pageCount INTEGER NOT NULL,
        description TEXT NOT NULL,
        coverImagePath TEXT,
        status TEXT NOT NULL,
        tags TEXT NOT NULL
      )
    ''');
    // Yeni tabloları da onCreate içinde oluşturuyoruz,
    // ancak existing databases için onUpgrade'i kullanacağız.
    await _createBookListsTables(db); // Yeni tablo oluşturma metodu çağrıldı
  }

  // Veritabanı versiyonu yükseltildiğinde çalışır
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 1'den Version 2'ye geçerken yeni tabloları oluştur
      await _createBookListsTables(db);
    }
    // Gelecekteki versiyon yükseltmeleri buraya eklenebilir (örn: if (oldVersion < 3) ...)
  }

  // Yeni kitap listeleri tablolarını oluşturan yardımcı metot
  Future _createBookListsTables(Database db) async {
    await db.execute('''
      CREATE TABLE book_lists(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE, -- Liste adları benzersiz olmalı
        description TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE book_list_items(
        listId INTEGER NOT NULL,
        bookId INTEGER NOT NULL,
        FOREIGN KEY (listId) REFERENCES book_lists (id) ON DELETE CASCADE,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE,
        PRIMARY KEY (listId, bookId) -- Bir liste ve kitap kombinasyonu benzersiz olmalı
      )
    ''');
  }

  // --- Kitaplar İçin CRUD Metotları (Mevcut) ---

  // Yeni kitap ekler
  Future<int> insertBook(Book book) async {
    Database db = await instance.database;
    try {
      int id = await db.insert('books', book.toMap());
      print('DatabaseHelper: Kitap eklendi, ID: $id, Başlık: ${book.title}');
      return id;
    } catch (e) {
      print('DatabaseHelper - insertBook Hatası: $e');
      rethrow; // Hatayı tekrar fırlat ki çağıran metod (BookFormScreen) yakalayabilsin
    }
  }

  // Tüm kitapları getirir
  Future<List<Book>> getBooks() async {
    Database db = await instance.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('books');
      print('DatabaseHelper: ${maps.length} kitap getirildi.');
      return List.generate(maps.length, (i) {
        return Book.fromMap(maps[i]);
      });
    } catch (e) {
      print('DatabaseHelper - getBooks Hatası: $e');
      rethrow;
    }
  }

  // ID'ye göre kitap getirir
  Future<Book?> getBookById(int id) async {
    Database db = await instance.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'books',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return Book.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('DatabaseHelper - getBookById Hatası: $e');
      rethrow;
    }
  }


  // Kitabı günceller
  Future<int> updateBook(Book book) async {
    Database db = await instance.database;
    try {
      int count = await db.update(
        'books',
        book.toMap(),
        where: 'id = ?',
        whereArgs: [book.id],
      );
      print('DatabaseHelper: Kitap güncellendi, ID: ${book.id}, Satır sayısı: $count, Başlık: ${book.title}');
      return count;
    } catch (e) {
      print('DatabaseHelper - updateBook Hatası: $e');
      rethrow;
    }
  }

  // Kitabı siler
  Future<int> deleteBook(int id) async {
    Database db = await instance.database;
    try {
      int count = await db.delete(
        'books',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseHelper: Kitap silindi, ID: $id, Silinen satır: $count');
      return count;
    } catch (e) {
      print('DatabaseHelper - deleteBook Hatası: $e');
      rethrow;
    }
  }

  // --- Yeni: Kitap Listeleri İçin CRUD Metotları ---

  // Yeni kitap listesi ekler
  Future<int> insertBookList(BookList bookList) async {
    Database db = await instance.database;
    try {
      int id = await db.insert('book_lists', bookList.toMap());
      print('DatabaseHelper: Liste eklendi, ID: $id, Adı: ${bookList.name}');
      return id;
    } catch (e) {
      print('DatabaseHelper - insertBookList Hatası: $e');
      rethrow;
    }
  }

  // Tüm kitap listelerini getirir
  Future<List<BookList>> getBookLists() async {
    Database db = await instance.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('book_lists');
      print('DatabaseHelper: ${maps.length} liste getirildi.');
      return List.generate(maps.length, (i) {
        return BookList.fromMap(maps[i]);
      });
    } catch (e) {
      print('DatabaseHelper - getBookLists Hatası: $e');
      rethrow;
    }
  }

  // Belirli bir kitap listesini ID'ye göre getirir
  Future<BookList?> getBookListById(int id) async {
    Database db = await instance.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'book_lists',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return BookList.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('DatabaseHelper - getBookListById Hatası: $e');
      rethrow;
    }
  }

  // Kitap listesini günceller
  Future<int> updateBookList(BookList bookList) async {
    Database db = await instance.database;
    try {
      int count = await db.update(
        'book_lists',
        bookList.toMap(),
        where: 'id = ?',
        whereArgs: [bookList.id],
      );
      print('DatabaseHelper: Liste güncellendi, ID: ${bookList.id}, Satır sayısı: $count, Adı: ${bookList.name}');
      return count;
    } catch (e) {
      print('DatabaseHelper - updateBookList Hatası: $e');
      rethrow;
    }
  }

  // Kitap listesini siler
  Future<int> deleteBookList(int id) async {
    Database db = await instance.database;
    try {
      int count = await db.delete(
        'book_lists',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('DatabaseHelper: Liste silindi, ID: $id, Silinen satır: $count');
      return count;
    } catch (e) {
      print('DatabaseHelper - deleteBookList Hatası: $e');
      rethrow;
    }
  }

  // --- Yeni: book_list_items için Metotlar ---

  // Kitabı bir listeye ekler
  Future<void> addBookToBookList(int listId, int bookId) async {
    Database db = await instance.database;
    try {
      await db.insert(
        'book_list_items',
        {'listId': listId, 'bookId': bookId},
        conflictAlgorithm: ConflictAlgorithm.ignore, // Zaten varsa tekrar ekleme
      );
      print('DatabaseHelper: Kitap ID: $bookId, Liste ID: $listId\'ye eklendi.');
    } catch (e) {
      print('DatabaseHelper - addBookToBookList Hatası: $e');
      rethrow;
    }
  }

  // Kitabı bir listeden çıkarır
  Future<void> removeBookFromBookList(int listId, int bookId) async {
    Database db = await instance.database;
    try {
      await db.delete(
        'book_list_items',
        where: 'listId = ? AND bookId = ?',
        whereArgs: [listId, bookId],
      );
      print('DatabaseHelper: Kitap ID: $bookId, Liste ID: $listId\'den çıkarıldı.');
    } catch (e) {
      print('DatabaseHelper - removeBookFromBookList Hatası: $e');
      rethrow;
    }
  }

  // Bir listedeki tüm kitapları getirir
  Future<List<Book>> getBooksInList(int listId) async {
    Database db = await instance.database;
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT books.* FROM books
        INNER JOIN book_list_items ON books.id = book_list_items.bookId
        WHERE book_list_items.listId = ?
      ''', [listId]);
      print('DatabaseHelper: Liste ID: $listId için ${maps.length} kitap getirildi.');
      return List.generate(maps.length, (i) {
        return Book.fromMap(maps[i]);
      });
    } catch (e) {
      print('DatabaseHelper - getBooksInList Hatası: $e');
      rethrow;
    }
  }

  // Bir kitabın hangi listelerde olduğunu kontrol eder
  Future<List<int>> getBookListIdsForBook(int bookId) async {
    Database db = await instance.database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'book_list_items',
        columns: ['listId'],
        where: 'bookId = ?',
        whereArgs: [bookId],
      );
      return List.generate(maps.length, (i) => maps[i]['listId'] as int);
    } catch (e) {
      print('DatabaseHelper - getBookListIdsForBook Hatası: $e');
      rethrow;
    }
  }

  // Bir listedeki kitap sayısını döndürür
  Future<int> getBookCountInList(int listId) async {
    Database db = await instance.database;
    try {
      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT COUNT(*) FROM book_list_items WHERE listId = ?',
        [listId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('DatabaseHelper - getBookCountInList Hatası: $e');
      rethrow;
    }
  }
}