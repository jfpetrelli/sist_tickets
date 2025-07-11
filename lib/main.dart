// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/screens/splash/splash_screen.dart'; // Importa la nueva pantalla
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/providers/ticket_provider.dart';
import 'package:sist_tickets/api/api_service.dart';
import 'package:sist_tickets/providers/user_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(
          create: (context) => TicketProvider(
            context.read<ApiService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Sistema de Tickets',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: kPrimaryColor,
          colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
          useMaterial3: true,
        ),
        home: const SplashScreen(), // 👈 ¡Aquí está el cambio!
      ),
    );
  }
}
