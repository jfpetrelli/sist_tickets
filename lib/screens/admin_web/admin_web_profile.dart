// ignore_for_file: unnecessary_import
import 'dart:typed_data'; // Necesario para Uint8List
import 'package:flutter/foundation.dart'; // Necesario para kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Importar image_picker
import 'package:provider/provider.dart'; // Importar provider
import 'package:sist_tickets/api/api_config.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/providers/user_provider.dart';
import '../../api/api_service.dart'; // Importar ApiService
import '../home/change_password_screen.dart';
import '../../models/usuario.dart'; // Importar Usuario
import 'package:sist_tickets/screens/login/login_screen.dart';

class AdminWebProfile extends StatefulWidget {
  const AdminWebProfile({super.key});

  @override
  State<AdminWebProfile> createState() => _AdminWebProfileState();
}

class _AdminWebProfileState extends State<AdminWebProfile> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false; // Estado para indicar si se está subiendo
  Map<String, int>?
      _userStats; // Estado para guardar las estadísticas del usuario
  bool _isLoadingStats = true; // Estado para la carga de estadísticas
  int _photoCacheBuster = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserStats();
    });
  }

  Future<void> _fetchUserStats() async {
    setState(() {
      _isLoadingStats = true;
      _userStats = null;
    });
    try {
      final apiService = context.read<ApiService>();
      final currentUser = context.read<UserProvider>().user;

      if (currentUser == null) {
        throw Exception("Usuario no disponible");
      }

      final allStats = await apiService.getTicketStats();
      final List<dynamic>? statsPorTecnico =
          allStats['tickets_por_tecnico_y_estado'];

      if (statsPorTecnico != null) {
        final userSpecificStats = statsPorTecnico.firstWhere(
          (stat) => stat['id_personal_asignado'] == currentUser.idPersonal,
          orElse: () => null,
        );

        if (userSpecificStats != null) {
          setState(() {
            _userStats = {
              'pendientes': userSpecificStats['pendientes'] ?? 0,
              'en_progreso': userSpecificStats['en_progreso'] ?? 0,
              'finalizados': userSpecificStats['finalizados'] ?? 0,
              'cancelados': userSpecificStats['cancelados'] ?? 0,
            };
          });
        } else {
          setState(() {
            _userStats = {
              'pendientes': 0,
              'en_progreso': 0,
              'finalizados': 0,
              'cancelados': 0,
            };
          });
        }
      } else {
        setState(() {
          _userStats = {
            'pendientes': 0,
            'en_progreso': 0,
            'finalizados': 0,
            'cancelados': 0,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      }
      setState(() {
        _userStats = {
          'pendientes': 0,
          'en_progreso': 0,
          'finalizados': 0,
          'cancelados': 0,
        };
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  void _showImagePickerOptions(BuildContext context, Usuario user) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.gallery, user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.camera, user);
                },
              ),
              if (user.profilePhotoUrl != null &&
                  user.profilePhotoUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar foto',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteProfilePhoto(context, user);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source, Usuario user) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final apiService = context.read<ApiService>();
        final userProvider = context.read<UserProvider>();

        final Uint8List imageBytes = await image.readAsBytes();
        final String fileName = image.name;

        final updatedUser = await apiService.uploadProfilePhoto(
            user.idPersonal, imageBytes, fileName);

        userProvider.setUser(updatedUser);

        setState(() {
          _photoCacheBuster = DateTime.now().millisecondsSinceEpoch;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada.'),
            backgroundColor: kSuccessColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir la foto: $e'),
            backgroundColor: kErrorColor,
          ),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteProfilePhoto(BuildContext context, Usuario user) async {
    setState(() => _isUploading = true);
    try {
      final apiService = context.read<ApiService>();
      final userProvider = context.read<UserProvider>();

      final updatedUser = await apiService.deleteProfilePhoto(user.idPersonal);

      userProvider.setUser(updatedUser);

      setState(() {
        _photoCacheBuster = DateTime.now().millisecondsSinceEpoch;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil eliminada.'),
          backgroundColor: Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la foto: $e'),
          backgroundColor: kErrorColor,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildProfileCard(context, user),
                const SizedBox(height: 20),
                _buildStatsSection(),
                const SizedBox(height: 20),
                _buildSettingsSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Usuario? user) {
    final apiService = context.read<ApiService>();
    final String? currentToken = apiService.getToken();

    String? profileImageEndpointUrl;
    if (user?.idPersonal != null &&
        user?.profilePhotoUrl != null &&
        user!.profilePhotoUrl!.isNotEmpty) {
      profileImageEndpointUrl =
          '${ApiConfig.baseUrl}/usuarios/${user.idPersonal}/profile_photo?t=$_photoCacheBuster';
    }

    final String casosCompletados =
        _isLoadingStats ? '...' : (_userStats?['finalizados'] ?? 0).toString();
    final String casosPendientes =
        _isLoadingStats ? '...' : (_userStats?['pendientes'] ?? 0).toString();
    final String casosEnProgreso =
        _isLoadingStats ? '...' : (_userStats?['en_progreso'] ?? 0).toString();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              kPrimaryColor,
              kPrimaryColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  backgroundImage: (profileImageEndpointUrl != null &&
                          currentToken != null)
                      ? NetworkImage(
                          profileImageEndpointUrl,
                          headers: {'Authorization': 'Bearer $currentToken'},
                        )
                      : null,
                  child: (profileImageEndpointUrl == null ||
                          currentToken == null)
                      ? const Icon(Icons.person, size: 50, color: kPrimaryColor)
                      : null,
                ),
                if (_isUploading)
                  const Positioned(
                      bottom: 0,
                      right: 0,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)),
                      )),
                if (!_isUploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          if (user != null) {
                            _showImagePickerOptions(context, user);
                          }
                        },
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child:
                              Icon(Icons.edit, size: 18, color: kPrimaryColor),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              user?.nombre ?? 'Nombre de Usuario',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 5),
            Text(
              user?.email ?? 'email@example.com',
              style:
                  TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
            ),
            if (user?.idTipo == 2)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Administrador',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            if (user?.idTipo == 1)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Técnico',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Casos\\nCompletados', casosCompletados),
                _buildStatItem('Casos\\nPendientes', casosPendientes),
                _buildStatItem('Casos\\nEn Progreso', casosEnProgreso),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 5),
        Text(label,
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Estadísticas',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800])),
        const SizedBox(height: 10),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                _buildStatRow('Tiempo promedio de respuesta', '2.5 horas'),
                const Divider(),
                _buildStatRow('Satisfacción del cliente', '98%'),
                const Divider(),
                _buildStatRow('Casos resueltos este mes', '15'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 14, color: Colors.black87)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor)),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Configuración',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800])),
        const SizedBox(height: 10),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              _buildSettingTile('Cambiar Contraseña', Icons.lock_outline, () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen()));
              }),
              const Divider(height: 1),
              _buildSettingTile('Cerrar sesión', Icons.exit_to_app,
                  () => _handleLogout(context),
                  isDestructive: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(String title, IconData icon, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : kPrimaryColor),
      title: Text(title,
          style: TextStyle(color: isDestructive ? Colors.red : Colors.black87)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
