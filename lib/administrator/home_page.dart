// lib/administrator/home_page.dart
import 'package:flutter/material.dart';
import 'package:sist_tickets/app_template.dart'; 
import 'package:sist_tickets/administrator/new_case_content.dart';
import 'package:sist_tickets/administrator/cases_content.dart'; 
import 'package:sist_tickets/administrator/profile_content.dart'; 

const Color kPrimaryColor = Color(0xFFE74C3C);

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  late final List<Widget> _screenBodies;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenBodies = <Widget>[

      SizedBox.expand(
        child: NewCaseContent(onTabSelected: _onBottomItemTapped),
      ),
      const CasesContent(),
      const ProfileContent(), 
    ];
  }

  void _onBottomItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    final List<BottomNavigationBarItem> _bottomNavBarItems = const <BottomNavigationBarItem>[
      BottomNavigationBarItem(
        icon: Icon(Icons.note_add_outlined),
        label: 'Nuevo Caso',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.list_alt),
        label: 'Casos',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    return AppTemplate(
      body: _screenBodies.elementAt(_selectedIndex),
      appBarTitle: '',
      appBarTitleStyle: const TextStyle(color: Colors.white),
      appBarColor: kPrimaryColor,
      leadingAppBarIcon: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      appBarActions: [
        SizedBox(
          width: screenSize.width * 0.4,
          child: const TextField(
            decoration: InputDecoration(
              hintText: 'Buscar',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            ),
            style: TextStyle(color: Colors.white),
            cursorColor: Colors.white,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () {
            print('Buscando...');
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {
            print('Notificaciones!');
          },
        ),
        const SizedBox(width: 8),
      ],
      bottomNavigationBar: BottomNavigationBar(
        items: _bottomNavBarItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        backgroundColor: kPrimaryColor,
        onTap: _onBottomItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: kPrimaryColor,
              ),
              child: Text(
                'Menú de Tickets',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Inicio'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Acerca de'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
