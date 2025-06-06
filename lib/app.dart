import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sist_tickets/administrator/home_page.dart';
import 'package:sist_tickets/constants.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Sistema de Tickets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
} 