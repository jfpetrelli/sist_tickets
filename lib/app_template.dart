// lib/app_template.dart
import 'package:flutter/material.dart';

class AppTemplate extends StatelessWidget {
  final Widget body;
  final String appBarTitle;
  final TextStyle? appBarTitleStyle; // <--- ¡NUEVO PARÁMETRO AQUÍ!
  final Color appBarColor;
  final Widget? leadingAppBarIcon;
  final List<Widget>? appBarActions;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final FloatingActionButton? floatingActionButton;

  const AppTemplate({
    super.key,
    required this.body,
    required this.appBarTitle,
    this.appBarTitleStyle, // <--- ¡AÑÁDELO AL CONSTRUCTOR!
    required this.appBarColor,
    this.leadingAppBarIcon,
    this.appBarActions,
    this.bottomNavigationBar,
    this.drawer,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: appBarTitleStyle ?? const TextStyle(color: Colors.white), // Usa el estilo nuevo o el por defecto
        ),
        backgroundColor: appBarColor,
        leading: leadingAppBarIcon,
        actions: appBarActions,
        // Eliminamos el `elevation` de aquí para que la AppBar tenga una apariencia más limpia por defecto
        // y se pueda controlar desde donde se usa el AppTemplate si se quiere sombra.
        elevation: 0, // Por ejemplo, sin sombra por defecto
      ),
      body: Container(
        color: Colors.grey[200], // Fondo por defecto para el body
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
    );
  }
}