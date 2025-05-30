// lib/app_template.dart
import 'package:flutter/material.dart';

class AppTemplate extends StatelessWidget {
  final String appBarTitle;
  final Color appBarColor;
  final TextStyle? appBarTitleStyle;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? leadingAppBarIcon;
  final List<Widget>? appBarActions;
  final GlobalKey<ScaffoldState>? scaffoldKey; // <-- ESTA LÍNEA ES LA IMPORTANTE AHORA

  const AppTemplate({
    super.key,
    required this.appBarTitle,
    this.appBarColor = Colors.blue,
    this.appBarTitleStyle,
    required this.body,
    this.bottomNavigationBar,
    this.drawer,
    this.leadingAppBarIcon,
    this.appBarActions,
    this.scaffoldKey, // <-- Y ESTA LÍNEA EN EL CONSTRUCTOR
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey, // Asigna la key al Scaffold
      appBar: AppBar(
        backgroundColor: appBarColor,
        leading: leadingAppBarIcon,
        title: Text(
          appBarTitle,
          style: appBarTitleStyle ?? const TextStyle(color: Colors.white),
        ),
        actions: appBarActions,
        centerTitle: true,
      ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
    );
  }
}