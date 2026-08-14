import 'package:flutter/material.dart';
import 'package:pricimal/home.dart';
import 'package:go_router/go_router.dart';
import 'package:pricimal/routing.dart';


void main() {
  runApp(const PricimalApp());
}

class PricimalApp extends StatelessWidget {
  const PricimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pricimal',
      routerConfig: router,
      theme: ThemeData(
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xBC35E544),
        ),
      ),
      // home: const HomePage(),
    );
  }
}
