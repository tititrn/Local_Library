// lib/screens/main_app_shell.dart

import 'package:flutter/material.dart';
import 'home_screen.dart'; // Mevcut ana ekranınız
import 'books_screen.dart'; // Tüm kitapların listelendiği ayrı bir ekran
import 'categories_screen.dart'; // Kategoriler ekranı
import 'lists_screen.dart'; // Yeni Listeler ekranı

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0; // Seçili sekmenin indeksi

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(), // Ana Sayfa
    const BooksScreen(), // Kitaplar
    const CategoriesScreen(), // Kategoriler
    const ListsScreen(), // Listeler ekranı eklendi
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex), // Seçili sekmeye göre ekranı göster
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Kitaplar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category), // Kategori ikonu
            label: 'Kategoriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt), // Liste ikonu
            label: 'Listeler',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor, // Seçili öğenin rengi
        unselectedItemColor: Colors.grey, // Seçili olmayan öğelerin rengi
        onTap: _onItemTapped, // Sekme tıklama işleyicisi
        type: BottomNavigationBarType.fixed, // 4 veya daha fazla öğe için gerekli
      ),
    );
  }
}