
import 'package:flutter/material.dart';
import 'package:sist_tickets/app_template.dart';
import 'package:sist_tickets/administrator/new_case_content.dart';
import 'package:sist_tickets/administrator/cases_content.dart';
import 'package:sist_tickets/administrator/profile_content.dart'; 
import 'package:sist_tickets/administrator/case_detail_content.dart';
import 'package:sist_tickets/administrator/reports_content.dart'; 
import 'package:sist_tickets/administrator/confirmation_signature_content.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/services/api_service.dart';
import 'package:sist_tickets/login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1; 

  final List<Widget> _widgetOptions = <Widget>[];

  String? _currentCaseDetailId;
  bool _showingConfirmationSignature = false;
  bool _showingReportsFromDrawer = false;

  @override
  void initState() {
    super.initState();
    
    _widgetOptions.addAll([
      const NewCaseContent(), 
      CasesContent(onShowCaseDetail: _showCaseCaseDetail), 
      
      ProfileContent(onLogout: () => _handleLogout(context)), 
    ]);
  }

  void _showCaseCaseDetail(String caseId) {
    setState(() {
      _currentCaseDetailId = caseId;
      _showingConfirmationSignature = false;
      _showingReportsFromDrawer = false; 
      _selectedIndex = 1; 
    });
  }

  void _hideCaseDetail() {
    setState(() {
      _currentCaseDetailId = null;
      
    });
  }

  void _showConfirmationSignatureScreen() {
    setState(() {
      _showingConfirmationSignature = true;
      _showingReportsFromDrawer = false; 
    });
  }

  void _hideConfirmationSignatureScreen() {
    setState(() {
      _showingConfirmationSignature = false;
    });
  }

  void _onBottomItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _currentCaseDetailId = null; 
      _showingConfirmationSignature = false; 
      _showingReportsFromDrawer = false; 
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    if (_showingConfirmationSignature) {
      bodyContent = ConfirmationSignatureContent(
        caseId: _currentCaseDetailId ?? 'default_case_id',
        onBack: _hideConfirmationSignatureScreen,
      );
    } else if (_currentCaseDetailId != null && _selectedIndex == 1) {
      bodyContent = CaseDetailContent(
        caseId: _currentCaseDetailId!,
        onBack: _hideCaseDetail,
        onShowConfirmationSignature: _showConfirmationSignatureScreen,
      );
    } else if (_showingReportsFromDrawer) {
      
      bodyContent = const ReportsContent();
    } else {
      
      bodyContent = _widgetOptions.elementAt(_selectedIndex);
    }

    return AppTemplate(
      scaffoldKey: _scaffoldKey,
      body: bodyContent,
      bottomNavigationBar: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onBottomItemTapped,
          backgroundColor: kPrimaryColor,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.6),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: 'Nuevo Caso',
              activeIcon: Icon(Icons.add_circle_outline, size: 28),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Casos',
              activeIcon: Icon(Icons.list_alt, size: 28),
            ),
            
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Perfil',
              activeIcon: Icon(Icons.person_outline, size: 28),
            ),
          ],
        ),
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
                      'Juan Cruz Ortega',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Último ingreso: 07/02/2024 11:30',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white),
                title: const Text(
                  'Inicio',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'TAREAS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.white),
                title: const Text(
                  'Nuevo Caso',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _onBottomItemTapped(0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.list_alt, color: Colors.white),
                title: const Text(
                  'Casos',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _onBottomItemTapped(1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.white),
                title: const Text(
                  'Reportes',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    
                    _showingReportsFromDrawer = true;
                    
                    _currentCaseDetailId = null;
                    _showingConfirmationSignature = false;
                    
                    
                    
                    
                  });
                  Navigator.pop(context);
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'USUARIO',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline, color: Colors.white),
                title: const Text(
                  'Perfil',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    _selectedIndex = 2; 
                    _currentCaseDetailId = null;
                    _showingConfirmationSignature = false;
                    _showingReportsFromDrawer = false; 
                  });
                  Navigator.pop(context);
                },
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.white),
                title: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _handleLogout(context); 
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Está seguro que desea cerrar sesión?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                ApiService.logout();
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