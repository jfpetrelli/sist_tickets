import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart';

class AppTemplate extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final String? title;

  const AppTemplate({
    super.key,
    required this.scaffoldKey,
    required this.body,
    this.bottomNavigationBar,
    this.drawer,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: title != null
            ? Text(title!, style: const TextStyle(color: Colors.white))
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: drawer,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
