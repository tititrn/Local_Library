// lib/main.dart
import 'package:flutter/material.dart';
import 'package:kitap_kutuphanem/screens/main_app_shell.dart'; // Yeni dosyanızı import edin

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kişisel Kütüphanem',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainAppShell(), // Burayı MainAppShell olarak değiştirin
    );
  }
}