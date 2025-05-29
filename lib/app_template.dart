// lib/app_template.dart
import 'package:flutter/material.dart';

class AppTemplate extends StatelessWidget {
  final Widget body;
  final String appBarTitle;
  final TextStyle? appBarTitleStyle; 
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
    this.appBarTitleStyle, 
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
          style: appBarTitleStyle ?? const TextStyle(color: Colors.white), 
        ),
        backgroundColor: appBarColor,
        leading: leadingAppBarIcon,
        actions: appBarActions,
        elevation: 0, 
      ),
      body: Container(
        color: Colors.grey[200], 
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
    );
  }
}
