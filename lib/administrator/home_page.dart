// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:sist_tickets/app_template.dart';
import 'package:sist_tickets/administrator/new_case_content.dart' hide kPrimaryColor;
import 'package:sist_tickets/administrator/cases_content.dart';
import 'package:sist_tickets/administrator/profile_content.dart' hide kPrimaryColor;
import 'package:sist_tickets/administrator/case_detail_content.dart';
import 'package:sist_tickets/constants.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  String? _currentCaseDetailId; // ID del caso en detalle, null si no hay detalle
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Para controlar el Drawer

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Método para mostrar el detalle de un caso (llamado desde CasesContent)
  // ESTA ES LA FUNCIÓN QUE DEBE ESTAR DEFINIDA
  void _showCaseCaseDetail(String caseId) {
    setState(() {
      _currentCaseDetailId = caseId;
      _selectedIndex = 1; // Asegurarse de que la pestaña "Casos" esté seleccionada
    });
  }

  // Método para ocultar el detalle y volver a la lista (llamado desde CaseDetailContent)
  void _hideCaseDetail() {
    setState(() {
      _currentCaseDetailId = null;
    });
  }

  void _onBottomItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _currentCaseDetailId = null; // Siempre ocultar el detalle al cambiar de pestaña
    });
    // Cierra el drawer si está abierto al cambiar de pestaña
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }

  // Método para obtener el widget del cuerpo de la pantalla basado en el estado
  Widget _getBodyContent() {
    if (_selectedIndex == 1 && _currentCaseDetailId != null) {
      // Si estamos en la pestaña "Casos" y hay un caso seleccionado para detalle
      return CaseDetailContent(
        caseId: _currentCaseDetailId!,
        onBackToList: _hideCaseDetail, // Pasa el callback para volver a la lista
      );
    } else {
      // De lo contrario, devuelve el widget normal para la pestaña seleccionada
      switch (_selectedIndex) {
        case 0:
          return SizedBox.expand(
            child: NewCaseContent(onTabSelected: _onBottomItemTapped),
          );
        case 1:
          return CasesContent(
            onShowCaseDetail: _showCaseCaseDetail, // <-- Usando la función aquí
          );
        case 2:
          return const ProfileContent();
        default:
          return const Center(child: Text('Pantalla no encontrada'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    final List<BottomNavigationBarItem> bottomNavBarItems = const <BottomNavigationBarItem>[
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

    const String fixedAppBarTitle = '';
    final Widget fixedLeadingAppBarIcon = Builder(
      builder: (context) {
        return IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        );
      },
    );
    final List<Widget> fixedAppBarActions = [
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
    ];

    return AppTemplate(
      scaffoldKey: _scaffoldKey,
      body: _getBodyContent(),
      appBarTitle: fixedAppBarTitle,
      appBarTitleStyle: const TextStyle(color: Colors.white),
      appBarColor: kPrimaryColor,
      leadingAppBarIcon: fixedLeadingAppBarIcon,
      appBarActions: fixedAppBarActions,
      bottomNavigationBar: BottomNavigationBar(
        items: bottomNavBarItems,
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
              onTap: () {
                _onBottomItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Nuevo Caso'),
              onTap: () {
                _onBottomItemTapped(0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Casos'),
              onTap: () {
                _onBottomItemTapped(1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: () {
                _onBottomItemTapped(2);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {
                print('Ir a Configuración');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Acerca de'),
              onTap: () {
                print('Ir a Acerca de');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}