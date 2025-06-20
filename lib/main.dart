import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/login_screen.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/provider/ticket_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TicketProvider(),
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
