import 'package:flutter/material.dart';
import 'screens/vertical_clock_page.dart';

void main() {
  runApp(const DikeySaatApp());
}

class DikeySaatApp extends StatelessWidget {
  const DikeySaatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sultan Mescidi Dikey Saat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
      ),
      home: const VerticalClockPage(),
    );
  }
}
