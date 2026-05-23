import 'package:flutter/material.dart';
import 'screens/pantalla_landing.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bienes GO',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF34C759)),
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(const Color(0xFF007AFF)),
          trackColor: WidgetStateProperty.all(
            const Color(0xFF007AFF).withValues(alpha: 0.2),
          ),
          thickness: WidgetStateProperty.all(6),
          radius: const Radius.circular(10),
        ),
      ),
      home: const PantallaLanding()
    );
  }
}