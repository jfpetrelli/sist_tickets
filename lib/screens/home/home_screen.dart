// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/api/api_service.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/screens/home/cases_tab.dart';
import 'package:sist_tickets/screens/home/new_case_tab.dart';
import 'package:sist_tickets/screens/home/profile_tab.dart';
import 'package:sist_tickets/screens/login/login_screen.dart';
import 'package:sist_tickets/widgets/app_template.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const NewCaseTab(),
      const CasesTab(),
      ProfileTab(onLogout: () => _handleLogout(context)),
    ];
  }

  void _onBottomItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppTemplate(
      scaffoldKey: _scaffoldKey,
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomItemTapped,
        backgroundColor: kPrimaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Nuevo Caso',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Casos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: kPrimaryColor,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 50, bottom: 20),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: kPrimaryColor),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Juan Cruz Ortega', // Nombre de ejemplo
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      // Usando la fecha y hora actuales como ejemplo
                      'Último ingreso: 25/06/2025 19:10',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: Colors.white24)),
              ListTile(
                leading:
                    const Icon(Icons.add_circle_outline, color: Colors.white),
                title: const Text('Nuevo Caso',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  _onBottomItemTapped(0); // Cambia a la pestaña 0
                  Navigator.pop(context); // Cierra el drawer
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt, color: Colors.white),
                title:
                    const Text('Casos', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _onBottomItemTapped(1); // Cambia a la pestaña 1
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.white),
                title: const Text('Reportes',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer primero
                  // Y luego navega a la pantalla de Reportes.
                  // Descomenta la siguiente línea cuando hayas creado ReportsScreen.
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
                },
              ),
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(color: Colors.white24)),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.white),
                title:
                    const Text('Perfil', style: TextStyle(color: Colors.white)),
                onTap: () {
                  _onBottomItemTapped(2); // Cambia a la pestaña 2
                  Navigator.pop(context);
                },
              ),
              const Spacer(), // Empuja el último elemento al fondo
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.white),
                title: const Text('Cerrar Sesión',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context); // Cierra el drawer
                  _handleLogout(context); // Llama a la función de logout
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      // --- FIN DE LA CORRECCIÓN ---
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro que desea cerrar sesión?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                context.read<ApiService>().logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
