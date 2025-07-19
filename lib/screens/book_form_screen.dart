// lib/screens/book_form_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Sayfa sayısı için numara girişi kısıtlaması için
import 'package:image_picker/image_picker.dart'; // Resim seçici için
import 'dart:io'; // Dosya işlemleri için
import '../database/database_helper.dart'; // Book modelini ve DatabaseHelper'ı kullanmak için

class BookFormScreen extends StatefulWidget {
  final Book? book; // Bu, düzenleme veya barkoddan gelen kitap olabilir

  const BookFormScreen({super.key, this.book});

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>(); // Form doğrulama anahtarı
  // Metin giriş alanları için controller'lar
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _publisherController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _pageCountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController(); // Ekstra etiketler için

  String? _coverImagePath; // Kitap kapak resminin yolu
  bool _isEditing = false; // Düzenleme modunda mı?

  // Okuma durumu için
  String _selectedStatus = 'Okunmadı'; // Varsayılan durum
  final List<String> _readingStatuses = ['Okunmadı', 'Okundu'];

  @override
  void initState() {
    super.initState();
    // ÖNEMLİ DÜZELTME: _isEditing kontrolü ve veri doldurma mantığı.
    if (widget.book != null) {
      // Eğer bir Book nesnesi geldiyse
      if (widget.book!.id != null) {
        // Eğer gelen Book nesnesinin ID'si varsa, bu bir düzenleme işlemidir.
        _isEditing = true;
      }
      // ID'si olsun ya da olmasın (yani yeni kitap eklerken de),
      // gelen Book nesnesindeki verileri controller'lara doldur.
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _publisherController.text = widget.book!.publisher;
      _locationController.text = widget.book!.location;
      _pageCountController.text = widget.book!.pageCount.toString();
      _descriptionController.text = widget.book!.description;
      _coverImagePath = widget.book!.coverImagePath;
      _selectedStatus = widget.book!.status;
      _tagsController.text = widget.book!.tags; // Barkoddan gelen ISBN buraya gelecek
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _publisherController.dispose();
    _locationController.dispose();
    _pageCountController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  // Galeri veya kameradan resim seçmek için
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _coverImagePath = pickedFile.path;
      });
    }
  }

  // Kitabı kaydetme veya güncelleme
  Future<void> _saveBook() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Sayfa sayısı boşsa veya geçersizse 0 olarak ayarla
      int pageCount = int.tryParse(_pageCountController.text) ?? 0;

      final book = Book(
        id: _isEditing ? widget.book!.id : null, // Düzenleme ise ID'yi kullan, yeni ise null
        title: _titleController.text,
        author: _authorController.text,
        publisher: _publisherController.text,
        location: _locationController.text,
        pageCount: pageCount,
        description: _descriptionController.text,
        coverImagePath: _coverImagePath,
        status: _selectedStatus, // Seçilen durumu kullan
        tags: _tagsController.text, // Etiketleri kullan
      );

      try {
        if (_isEditing) {
          // Kitabı güncelle
          await DatabaseHelper.instance.updateBook(book);
        } else {
          // Yeni kitap ekle
          await DatabaseHelper.instance.insertBook(book);
        }
        if (mounted) {
          // Başarılı olursa önceki ekrana true ile dön
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          // Hata durumunda kullanıcıya bilgi ver
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kitap kaydedilirken bir hata oluştu: $e')),
          );
          print('Kitap kaydetme/güncelleme hatası: $e'); // Hata detayını konsola yazdır
        }
      }
    }
  }

  // Kitabı silme
  Future<void> _deleteBook() async {
    if (!_isEditing || widget.book?.id == null) return;

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kitabı Sil'),
          content: Text('${widget.book!.title} adlı kitabı silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await DatabaseHelper.instance.deleteBook(widget.book!.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kitap başarıyla silindi!')),
          );
          Navigator.pop(context, true); // Kitap silindi, önceki ekrana true ile dön
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kitap silinirken bir hata oluştu: $e')),
          );
          print('Kitap silme hatası: $e'); // Hata detayını konsola yazdır
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Kitabı Düzenle' : 'Yeni Kitap Ekle'),
        actions: [
          if (_isEditing) // Düzenleme modundaysa silme butonu göster
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteBook,
              tooltip: 'Kitabı Sil',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Başlık
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Kitap Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir kitap adı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // Yazar
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Yazar Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yazar adı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // Yayınevi
              TextFormField(
                controller: _publisherController,
                decoration: const InputDecoration(
                  labelText: 'Yayınevi',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              // Konum
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Kitap Konumu (Raf, Kutu vb.)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              // Sayfa Sayısı
              TextFormField(
                controller: _pageCountController,
                decoration: const InputDecoration(
                  labelText: 'Sayfa Sayısı',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Sadece rakam girişi
                validator: (value) {
                  if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                    return 'Lütfen geçerli bir sayı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              // Açıklama
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              // Etiketler
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Etiketler (virgülle ayırın)',
                  hintText: 'Bilim Kurgu, Fantastik, Roman, ISBN:1234567890', // Örnek olarak ISBN de gösterildi
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              // Okuma Durumu Seçimi
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Okuma Durumu',
                  border: OutlineInputBorder(),
                ),
                items: _readingStatuses.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
              ),
              const SizedBox(height: 16.0),
              // Kapak Resmi Seçimi
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kapak Resmi:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeri'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  if (_coverImagePath != null && _coverImagePath!.isNotEmpty)
                    Center(
                      child: Column(
                        children: [
                          _coverImagePath!.startsWith('http://') || _coverImagePath!.startsWith('https://')
                              ? Image.network(
                                  _coverImagePath!,
                                  height: 150,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                                  },
                                )
                              : File(_coverImagePath!).existsSync()
                                  ? Image.file(
                                      File(_coverImagePath!),
                                      height: 150,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                                      },
                                    )
                                  : const Text('Geçersiz Kapak Yolu'),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _coverImagePath = null; // Kapak resmini kaldır
                              });
                            },
                            child: const Text('Kapak Resmini Kaldır'),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text('Kapak resmi yok', textAlign: TextAlign.center),
                ],
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _saveBook, // Kaydetme metodunu çağır
                child: Text(_isEditing ? 'Kitabı Kaydet' : 'Kitap Ekle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}