import 'package:flutter/material.dart';
import 'folder.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Organizer',
      theme: ThemeData.light().copyWith(
        // Soft pastel palette
        primaryColor: Colors.lightBlue[300],
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightBlue[200],
          foregroundColor: Colors.black,
        ),
        cardColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[300],
          ),
        ),
      ),
      home: FolderScreen(),
    );
  }
}
