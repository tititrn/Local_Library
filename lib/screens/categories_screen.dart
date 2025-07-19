// lib/screens/categories_screen.dart

import 'package:flutter/material.dart';
import 'package:kitap_kutuphanem/screens/category_books_screen.dart'; // Yeni ekranı import ediyoruz

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  // BookFormScreen'de tanımladığımız sabit kategori listesini burada da kullanacağız.
  // Bu listeyi merkezi bir yerde tutmak daha iyi olabilir, şimdilik tekrar tanımlayalım.
  final List<String> _fixedCategories = const [
    'Edebiyat',
    'Roman',
    'Kişisel Gelişim',
    'Çocuk',
    'Tarih',
    'Bilimkurgu',
    'Fantastik',
    'Gerilim',
    'Klasikler',
  ];

  // Her kategori için özel bir ikon döndüren yardımcı metod
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Edebiyat':
        return Icons.auto_stories; // Kitap ikonu
      case 'Roman':
        return Icons.book; // Genel kitap ikonu
      case 'Kişisel Gelişim':
        return Icons.self_improvement; // Gelişim ikonu
      case 'Çocuk':
        return Icons.child_friendly; // Çocuk ikonu
      case 'Tarih':
        return Icons.history_edu; // Tarih ikonu
      case 'Bilimkurgu':
        return Icons.science; // Bilim ikonu
      case 'Fantastik':
        return Icons.castle; // Kale ikonu (fantastik için)
      case 'Gerilim':
        return Icons.crisis_alert; // Tehlike ikonu
      case 'Klasikler':
        return Icons.gavel; // Hukuk/klasik ikonu (daha uygun bir şey bulunabilir)
      default:
        return Icons.category; // Varsayılan kategori ikonu
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategoriler'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Her satırda 2 öğe
          crossAxisSpacing: 16.0, // Yatay boşluk
          mainAxisSpacing: 16.0, // Dikey boşluk
          childAspectRatio: 1.0, // Öğelerin kare olmasını sağlar (genişlik/yükseklik oranı)
        ),
        itemCount: _fixedCategories.length,
        itemBuilder: (context, index) {
          final category = _fixedCategories[index];
          return Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: () {
                // Tıklanan kategoriye göre yeni ekrana git
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryBooksScreen(categoryName: category),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(category), // Kategoriye özel ikon
                      size: 60, // İkon boyutu
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}