import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/screens/login/login_screen.dart'; // Nueva ruta
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/providers/ticket_provider.dart'; // Nueva ruta
import 'package:sist_tickets/api/api_service.dart'; // Nueva ruta

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider para registrar nuestros servicios y proveedores
    return MultiProvider(
      providers: [
        // Proveemos una única instancia de ApiService para toda la app.
        Provider<ApiService>(create: (_) => ApiService()),

        // ChangeNotifierProvider ahora crea TicketProvider con ApiService.
        ChangeNotifierProvider(
          create: (context) => TicketProvider(
            // Usamos context.read para obtener la instancia de ApiService recién creada.
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
        home: const LoginScreen(),
      ),
    );
  }
}
