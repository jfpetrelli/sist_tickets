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
import '../../models/usuario.dart'; // Importar Usuario

class ProfileTab extends StatefulWidget {
  // Convertido a StatefulWidget
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.onLogout,
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false; // Estado para indicar si se está subiendo
  Map<String, int>?
      _userStats; // Estado para guardar las estadísticas del usuario
  bool _isLoadingStats = true; // Estado para la carga de estadísticas

  @override
  void initState() {
    super.initState();
    // Llamar a _fetchUserStats después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserStats();
    });
  }

  // --- Función para obtener y filtrar estadísticas ---
  Future<void> _fetchUserStats() async {
    setState(() {
      _isLoadingStats = true;
      _userStats = null; // Limpiar stats anteriores
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
          orElse: () => null, // Devuelve null si no se encuentra el usuario
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
          // Si el usuario no tiene estadísticas, inicializamos a 0
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
        // Si no hay datos por técnico, inicializamos a 0
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
      // Inicializar a 0 en caso de error
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
  // --- FIN Nueva función ---

  // --- Función para mostrar opciones de imagen ---
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
                  user.profilePhotoUrl!.isNotEmpty) // Mostrar solo si hay foto
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Eliminar foto',
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _deleteProfilePhoto(
                        context, user); // Llamar a la función de eliminar
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // --- Función para seleccionar y subir la imagen ---
  Future<void> _pickAndUploadImage(ImageSource source, Usuario user) async {
    final XFile? image = await _picker.pickImage(source: source);

    if (image != null) {
      setState(() => _isUploading = true); // Iniciar indicador de carga
      try {
        final apiService = context.read<ApiService>();
        final userProvider = context.read<UserProvider>();

        // Leer los bytes de la imagen
        final Uint8List imageBytes = await image.readAsBytes();
        final String fileName = image.name;

        // Llamar al método de ApiService
        final updatedUser = await apiService.uploadProfilePhoto(
            // ignore: unnecessary_cast
            user.idPersonal,
            imageBytes,
            fileName);

        // Actualizar el UserProvider con la información actualizada del usuario
        userProvider.setUser(updatedUser);

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
        setState(() => _isUploading = false); // Finalizar indicador de carga
      }
    }
  }

  // --- Función para eliminar la foto de perfil ---
  Future<void> _deleteProfilePhoto(BuildContext context, Usuario user) async {
    setState(() => _isUploading = true); // Usamos el mismo indicador
    try {
      final apiService = context.read<ApiService>();
      final userProvider = context.read<UserProvider>();

      // Llamar al método de ApiService
      final updatedUser = await apiService.deleteProfilePhoto(user.idPersonal);

      // Actualizar el UserProvider
      userProvider.setUser(updatedUser);

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

  @override
  Widget build(BuildContext context) {
    // Escuchamos cambios en UserProvider
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final user = userProvider.user; // Obtenemos el usuario actual

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perfil',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              // Pasar el usuario al método _buildProfileCard
              _buildProfileCard(context, user), // Añadido context
              const SizedBox(height: 20),
              _buildStatsSection(),
              const SizedBox(height: 20),
              _buildSettingsSection(), // Mantenemos la sección de configuración
            ],
          ),
        );
      },
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
          '${ApiConfig.baseUrl}/usuarios/${user.idPersonal}/profile_photo';
      print("URL del endpoint de imagen de perfil: $profileImageEndpointUrl");
    }

    // --- Extraer valores de _userStats o mostrar '...' si está cargando ---
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              user?.email ?? 'email@example.com',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            if (user?.idTipo == 2) // Chequear si es Admin (tipo 2)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25), // Un fondo sutil
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Administrador',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (user?.idTipo == 1)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25), // Un fondo sutil
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Técnico',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // --- Usar los valores de _userStats ---
                _buildStatItem('Casos\nCompletados', casosCompletados),
                _buildStatItem('Casos\nPendientes', casosPendientes),
                _buildStatItem('Casos\nEn Progreso', casosEnProgreso),
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
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configuración',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 10),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
            children: [
              _buildSettingTile(
                'Cambiar Contraseña',
                Icons.lock_outline,
                () => print('Cambiar Contraseña'),
              ),
              const Divider(height: 1),
              _buildSettingTile(
                'Cerrar sesión',
                Icons.exit_to_app,
                // Llama al onLogout pasado al constructor
                () => widget.onLogout(),
                isDestructive: true,
              ),
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
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
