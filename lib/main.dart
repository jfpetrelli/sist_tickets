// lib/main.dart
import 'package:flutter/material.dart';
import 'package:sist_tickets/login_screen.dart';
import 'package:sist_tickets/constants.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Tickets',
      theme: ThemeData(
        
        primarySwatch: MaterialColor(
          kPrimaryColor.value,
          const <int, Color>{
            50: Color(0xFFFAEBEA),
            100: Color(0xFFF6D4D1),
            200: Color(0xFFF0B8B2),
            300: Color(0xFFEB9C93),
            400: Color(0xFFE7877A),
            500: kPrimaryColor,
            600: Color(0xFFE44535),
            700: Color(0xFFE03C2D),
            800: Color(0xFFDC3325),
            900: Color(0xFFD62618),
          },
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
