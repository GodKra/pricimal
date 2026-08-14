import 'package:flutter/material.dart';

void main() {
  runApp(const PricimalApp());
}

class PricimalApp extends StatelessWidget {
  const PricimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pricimal',
      theme: ThemeData(
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xBC35E544),
        ),
      ),
      home: const Scaffold(),
    );
  }
}
