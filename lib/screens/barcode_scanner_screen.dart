// lib/screens/barcode_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../database/database_helper.dart'; // Book modelini ve DatabaseHelper'ı kullanmak için
import 'book_form_screen.dart'; // BookFormScreen'e yönlendirmek için

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  String _scanResult = 'Tarama Bekleniyor';
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Ekran açılır açılmaz barkod taramasını başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanBarcode();
    });
  }

  // Barkod tarama işlemini başlatır
  Future<void> _scanBarcode() async {
    setState(() {
      _errorMessage = ''; // Önceki hata mesajını temizle
    });
    try {
      var result = await BarcodeScanner.scan();
      setState(() {
        _scanResult = result.rawContent; // Taranan barkod içeriğini kaydet
      });

      if (result.rawContent.isNotEmpty) {
        // Barkod okunduysa kitap bilgilerini API'den çek
        await _fetchBookDetails(result.rawContent);
      } else {
        setState(() {
          _errorMessage = 'Barkod okunamadı veya boş.';
        });
        _showAlertDialog('Barkod Hatası', 'Barkod okunamadı veya boş. Tekrar deneyin.');
      }
    } on Exception catch (e) {
      // Taramada bir hata oluşursa
      setState(() {
        _scanResult = 'Hata: $e';
        _errorMessage = 'Barkod taraması sırasında bir hata oluştu: $e';
      });
      _showAlertDialog('Tarama Hatası', 'Barkod taraması iptal edildi veya bir hata oluştu: $e');
    }
  }

  // Google Books API'den kitap bilgilerini çeker
  Future<void> _fetchBookDetails(String isbn) async {
    setState(() {
      _isLoading = true; // Yükleme durumunu başlat
      _errorMessage = ''; // Hata mesajını temizle
    });

    final String apiUrl = 'https://www.googleapis.com/books/v1/volumes?q=isbn:$isbn';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['totalItems'] > 0) {
          // Kitap bulunduysa, ilk öğenin bilgilerini al
          final item = data['items'][0];
          final volumeInfo = item['volumeInfo'];

          // Gerekli bilgileri çek, yoksa varsayılan değerler ata
          final title = volumeInfo['title'] ?? 'Başlık Yok';
          final authors = (volumeInfo['authors'] as List?)?.join(', ') ?? 'Yazar Bilinmiyor';
          final publisher = volumeInfo['publisher'] ?? 'Yayınevi Bilinmiyor';
          final pageCount = volumeInfo['pageCount'] ?? 0;
          final description = volumeInfo['description'] ?? ''; // Açıklama eklendi
          final coverImageUrl = volumeInfo['imageLinks']?['thumbnail'] ?? ''; // Kapak resmi URL'si
          final categories = (volumeInfo['categories'] as List?)?.join(', ') ?? ''; // Kategoriler/Etiketler

          // Yeni bir Book objesi oluştur
          final fetchedBook = Book(
            title: title,
            author: authors,
            publisher: publisher,
            pageCount: pageCount,
            description: description,
            coverImagePath: coverImageUrl,
            location: '', // Konum API'dan gelmez, kullanıcı girecek
            status: 'Okunmadı', // Varsayılan okuma durumu
            tags: categories, // Otomatik doldurulan etiketler
          );

          setState(() {
            _isLoading = false; // Yükleme durumunu bitir
          });

          // Kitap bilgileri ile BookFormScreen'e yönlendir
          if (mounted) {
            print('BarcodeScannerScreen: BookFormScreen\'e yönlendiriliyor...');
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookFormScreen(book: fetchedBook), // fetchedBook'u gönder
              ),
            );
            print('BarcodeScannerScreen: BookFormScreen\'den dönen sonuç: $result');

            // BookFormScreen'den dönen sonuca göre HomeScreen'e geri dön
            if (result == true) {
              if (mounted) {
                print('BarcodeScannerScreen: Kitap başarıyla kaydedildi, HomeScreen\'e başarılı geri dönüş.');
                Navigator.pop(context, true); // Başarılı kaydetmeyi ana ekrana bildir
              }
            } else {
              if (mounted) {
                print('BarcodeScannerScreen: Kitap kaydedilmedi, HomeScreen\'e geri dönülüyor.');
                Navigator.pop(context, false); // Başarısız kaydetmeyi ana ekrana bildir
              }
            }
          }
        } else {
          // Kitap bulunamadıysa uyarı göster
          setState(() {
            _errorMessage = 'Bu ISBN ile kitap bulunamadı.';
            _isLoading = false;
          });
          _showAlertDialog('Kitap Bulunamadı', 'Veritabanında bu ISBN ile bir kitap bulunamadı.');
        }
      } else {
        // API yanıt kodu 200 değilse hata göster
        setState(() {
          _errorMessage = 'API hatası: ${response.statusCode}';
          _isLoading = false;
        });
        _showAlertDialog('API Hatası', 'Kitap bilgileri alınırken bir hata oluştu. Durum kodu: ${response.statusCode}');
      }
    } catch (e) {
      // Ağ veya diğer hataları yakala
      print('BarcodeScannerScreen - Ağ Hatası: $e');
      setState(() {
        _errorMessage = 'Ağ Hatası: $e';
        _isLoading = false;
      });
      _showAlertDialog('Ağ Hatası', 'Kitap bilgileri alınırken bir ağ hatası oluştu: $e');
    }
  }

  // Kullanıcıya bilgi veya hata mesajı göstermek için AlertDialog
  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Tamam'),
              onPressed: () {
                Navigator.of(context).pop(); // Alert'i kapat
                Navigator.of(context).pop(false); // BarcodeScannerScreen'i kapat ve başarısız olduğunu bildir
              },
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
        title: const Text('Barkod Tara'),
      ),
      body: Center(
        child: _isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Kitap bilgileri alınıyor...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(_scanResult),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _scanBarcode,
                    child: const Text('Tekrar Tara'),
                  ),
                ],
              ),
      ),
    );
  }
}