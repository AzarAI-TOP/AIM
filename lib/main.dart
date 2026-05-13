import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AimApp());
}

class AimApp extends StatelessWidget {
  const AimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIM - Advanced appImage Manager',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
