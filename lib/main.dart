import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/providers/adjunto_provider.dart';
import 'package:sist_tickets/providers/tipos_caso_provider.dart';
import 'package:sist_tickets/screens/splash/splash_screen.dart'; // Importa la nueva pantalla
import 'package:sist_tickets/screens/calificacion/calificacion_screen.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/providers/ticket_provider.dart';
import 'package:sist_tickets/api/api_service.dart';
import 'package:sist_tickets/providers/user_provider.dart';
import 'package:sist_tickets/providers/client_provider.dart';
import 'package:sist_tickets/providers/user_list_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show window;

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String? _getInitialRoute() {
    if (kIsWeb) {
      final path = html.window.location.pathname;
      if (path != null && path.startsWith('/calificar/')) {
        return path;
      }
    }
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider(
          create: (context) => AdjuntoProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(
          create: (context) => UserListProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(
          create: (context) => ClientProvider(
            context.read<ApiService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => TicketProvider(
            context.read<ApiService>(),
          ),
        ),
        ChangeNotifierProvider(
            create: (context) => TiposCasoProvider(context.read<ApiService>())),
      ],
      child: MaterialApp(
        title: 'Sistema de Tickets',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            primaryColor: kPrimaryColor,
            colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
            useMaterial3: true,
            inputDecorationTheme: kInputDecorationTheme),
        initialRoute: _getInitialRoute(),
        onGenerateRoute: (settings) {
          // Manejar rutas dinámicas como /calificar/:token
          if (settings.name != null &&
              settings.name!.startsWith('/calificar/')) {
            final token = settings.name!.substring('/calificar/'.length);
            return MaterialPageRoute(
              builder: (context) => CalificacionScreen(token: token),
              settings: settings, // Importante para mantener la ruta
            );
          }
          // Ruta por defecto
          if (settings.name == '/' || settings.name == null) {
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
              settings: settings,
            );
          }
          return null;
        },
      ),
    );
  }
}
