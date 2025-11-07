import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/screens/admin_web/admin_case_list.dart';
import 'package:sist_tickets/screens/admin_web/admin_case_detail.dart';
import 'package:sist_tickets/providers/user_provider.dart';
import 'package:sist_tickets/api/api_service.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/screens/login/login_screen.dart';
import 'package:sist_tickets/screens/usuarios/usuarios_screen.dart';
import 'package:sist_tickets/screens/clientes/clientes_screen.dart';
import 'package:sist_tickets/screens/reports/reports_content.dart';
import 'package:sist_tickets/screens/home/archivados_screen.dart';
import 'package:sist_tickets/screens/home/new_case_tab.dart';
import 'package:intl/intl.dart';

class AdminWebDashboard extends StatefulWidget {
  const AdminWebDashboard({super.key});

  @override
  State<AdminWebDashboard> createState() => _AdminWebDashboardState();
}

class _AdminWebDashboardState extends State<AdminWebDashboard> {
  int? _selectedCaseId;

  void _onCaseSelected(int caseId) {
    setState(() {
      _selectedCaseId = caseId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administrador'),
        centerTitle: true,
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: Container(
          color: kPrimaryColor,
          child: SafeArea(
            child: SingleChildScrollView(
              child: _buildDrawerContent(),
            ),
          ),
        ),
      ),
      body: Row(
        children: [
          // Master panel (lista de casos)
          Expanded(
            flex: 1,
            child: AdminCaseList(
              onCaseSelected: _onCaseSelected,
              selectedCaseId: _selectedCaseId,
            ),
          ),
          // Divider vertical
          const VerticalDivider(width: 1, thickness: 1),
          // Detail panel (detalle del caso seleccionado)
          Expanded(
            flex: 2,
            child: AdminCaseDetail(
              caseId: _selectedCaseId,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerContent() {
    return Column(
      children: [
        Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final user = userProvider.user;
            final lastLogin = user?.fechaIngreso != null
                ? DateFormat('dd/MM/yyyy HH:mm')
                    .format(user!.fechaIngreso!.toLocal())
                : 'No disponible';

            // Construir URL de la imagen de perfil con cache buster basado en la fecha del usuario
            String? profileImageUrl;
            final apiService = context.read<ApiService>();
            final token = apiService.getToken();

            if (user?.idPersonal != null &&
                user?.profilePhotoUrl != null &&
                user!.profilePhotoUrl!.isNotEmpty &&
                token != null) {
              // Usar timestamp actual como cache buster para refrescar la imagen
              final cacheBuster = DateTime.now().millisecondsSinceEpoch;
              profileImageUrl =
                  'http://localhost:8000/usuarios/${user.idPersonal}/profile_photo?t=$cacheBuster';
            }

            return Padding(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    backgroundImage: profileImageUrl != null && token != null
                        ? NetworkImage(
                            profileImageUrl,
                            headers: {'Authorization': 'Bearer $token'},
                          )
                        : null,
                    child: profileImageUrl == null || token == null
                        ? const Icon(Icons.person,
                            size: 40, color: kPrimaryColor)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.nombre ?? 'Nombre de Usuario',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Último ingreso: $lastLogin',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.white24)),
        ListTile(
          leading: const Icon(Icons.add_circle_outline, color: Colors.white),
          title:
              const Text('Nuevo Caso', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    title: const Text('Nuevo Caso'),
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                  ),
                  body: const NewCaseTab(),
                ),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.archive, color: Colors.white),
          title:
              const Text('Archivados', style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ArchivadosScreen()),
            );
          },
        ),
        const Divider(color: Colors.white24),
        Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.user?.idTipo == 2) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.people, color: Colors.white),
                    title: const Text('Usuarios',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UsuariosScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.business, color: Colors.white),
                    title: const Text('Clientes',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ClientesScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart, color: Colors.white),
                    title: const Text('Reportes',
                        style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ReportsContent()));
                    },
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.white24)),
        ListTile(
          leading: const Icon(Icons.exit_to_app, color: Colors.white),
          title: const Text('Cerrar Sesión',
              style: TextStyle(color: Colors.white)),
          onTap: () {
            Navigator.pop(context);
            _handleLogout(context);
          },
        ),
        const SizedBox(height: 16),
      ],
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
                context.read<UserProvider>().clearUser();
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
