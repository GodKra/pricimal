import 'package:flutter/material.dart';
import 'package:pricimal/util.dart';
import 'package:provider/provider.dart';
import 'package:pricimal/routing.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) {
        final repository = ShoppingRepository();
        repository.initializeRepository(sampleProducts, sampleShops, samplePrices);
        return repository;
      },
      child: PricimalApp(),
    )
  );
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
