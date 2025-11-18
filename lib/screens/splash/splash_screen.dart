// Crea un nuevo archivo, por ejemplo: lib/screens/splash/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/api/api_service.dart';
import 'package:sist_tickets/providers/user_provider.dart';
import 'package:sist_tickets/screens/home/home_screen.dart';
import 'package:sist_tickets/screens/login/login_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sist_tickets/utils/web_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Verificar si estamos en una ruta de calificación
    if (kIsWeb) {
      final path = getCurrentPath();
      if (path != null && path.startsWith('/calificar/')) {
        // No hacer nada, dejar que la ruta de calificación se maneje sola
        return;
      }
    }

    final apiService = context.read<ApiService>();
    final userProvider = context.read<UserProvider>();

    // Intenta cargar el token desde el almacenamiento seguro
    final hasToken = await apiService.tryLoadToken();

    if (hasToken) {
      try {
        // Si hay token, valida que siga siendo vigente pidiendo los datos del usuario
        final user = await apiService.getMe();
        userProvider.setUser(user);
        // Si todo va bien, vamos a la pantalla principal
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } catch (e) {
        // Si el token no es válido (p.ej. expiró en el servidor), vamos a login
        apiService.clearToken();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // Si no hay token guardado, vamos a login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Muestra un indicador de carga mientras se verifica la sesión
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
