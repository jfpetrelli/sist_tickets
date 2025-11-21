import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_list_provider.dart';
import '../../models/usuario.dart';
import 'edit_usuario_screen.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  void _showAddUsuarioModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) {
        return const _AddUsuarioForm();
      },
    );
  }

  Future<void> _refreshUsuarios() async {
    await Provider.of<UserListProvider>(context, listen: false)
        .fetchUsers(userType: null);
  }

  void _navigateToEditUsuario(BuildContext context, Usuario usuario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pasa el usuario a la nueva pantalla
        builder: (context) => EditUsuarioScreen(usuario: usuario),
      ),
    ).then((_) {
      // Refresca la lista cuando se vuelve de la pantalla de edición
      _refreshUsuarios();
    });
  }

  String _search = '';
  @override
  void initState() {
    super.initState();
    // Llama a fetchUsers con userType: null para traer todos los usuarios
    Future.microtask(() => Provider.of<UserListProvider>(context, listen: false)
        .fetchUsers(userType: null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserListProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.users.isEmpty) {
            return Center(child: Text(provider.errorMessage!));
          }
          final usuariosFiltrados = provider.users
              .where(
                  (u) => u.nombre.toLowerCase().contains(_search.toLowerCase()))
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar usuario...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 12),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchUsers(userType: null),
                  child: usuariosFiltrados.isEmpty
                      ? const Center(
                          child: Text('No hay usuarios para mostrar.'))
                      : ListView.separated(
                          itemCount: usuariosFiltrados.length,
                          separatorBuilder: (context, i) =>
                              const SizedBox(height: 8),
                          padding: const EdgeInsets.all(12),
                          itemBuilder: (context, index) {
                            final Usuario usuario = usuariosFiltrados[index];
                            final bool isActive = usuario.activo == true;
                            final bool isAdmin = usuario.idTipo == 2;
                            final String tipoText =
                                isAdmin ? 'ADMIN' : 'TÉCNICO';
                            final IconData tipoIcon = isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.engineering;
                            final Color tipoColor =
                                isAdmin ? Colors.purple : Colors.orange;

                            return Opacity(
                              opacity: isActive ? 1.0 : 0.5,
                              child: Card(
                                elevation: isActive ? 1 : 0,
                                color: isActive ? null : Colors.grey[100],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: isActive
                                      ? BorderSide.none
                                      : BorderSide(
                                          color: Colors.grey[300]!, width: 1),
                                ),
                                child: ListTile(
                                    dense: true,
                                    visualDensity:
                                        const VisualDensity(vertical: -4),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 0),
                                    leading: Container(
                                      alignment: Alignment.center,
                                      width: 40,
                                      child: Icon(
                                        Icons.person,
                                        color: isActive
                                            ? Colors.blueAccent
                                            : Colors.grey,
                                      ),
                                    ),
                                    title: Text(
                                      usuario.nombre,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        decoration: isActive
                                            ? null
                                            : TextDecoration.lineThrough,
                                      ),
                                    ),
                                    subtitle: Text(
                                      [usuario.email, usuario.telefonoMovil]
                                          .where((e) => (e ?? '').isNotEmpty)
                                          .join(' | '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isActive
                                            ? Colors.black54
                                            : Colors.black38,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          tipoIcon,
                                          size: 16,
                                          color: isActive
                                              ? tipoColor
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          tipoText,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isActive
                                                ? tipoColor
                                                : Colors.black45,
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      _navigateToEditUsuario(context, usuario);
                                    }),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 6,
        onPressed: () {
          _showAddUsuarioModal(context);
        },
        // ignore: sort_child_properties_last
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        tooltip: 'Agregar usuario',
      ),
    );
  }
}

class _AddUsuarioForm extends StatefulWidget {
  const _AddUsuarioForm();

  @override
  State<_AddUsuarioForm> createState() => __AddUsuarioFormState();
}

class __AddUsuarioFormState extends State<_AddUsuarioForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _idPersonalController = TextEditingController();
  final _idSucursalController = TextEditingController();
  final _idTipoController = TextEditingController();
  final _telefonoMovilController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fechaIngresoController = TextEditingController();
  final _fechaEgresoController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _idPersonalController.dispose();
    _idSucursalController.dispose();
    _idTipoController.dispose();
    _telefonoMovilController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fechaIngresoController.dispose();
    _fechaEgresoController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final nuevoUsuario = Usuario(
        idPersonal: DateTime.now().millisecondsSinceEpoch,
        idSucursal: int.tryParse(_idSucursalController.text) ?? 0,
        idTipo: int.tryParse(_idTipoController.text) ?? 0,
        nombre: _nombreController.text,
        activo: true,
        telefonoMovil: _telefonoMovilController.text,
        email: _emailController.text,
        fechaIngreso: _fechaIngresoController.text.isNotEmpty
            ? DateTime.tryParse(_fechaIngresoController.text)
            : null,
        fechaEgreso: _fechaEgresoController.text.isNotEmpty
            ? DateTime.tryParse(_fechaEgresoController.text)
            : null,
      );

      // 1. Obtenemos la referencia al provider
      final userProvider = Provider.of<UserListProvider>(context, listen: false);

      // 2. Ejecutamos la acción (esperamos a que termine)
      await userProvider.addUserWithPassword(nuevoUsuario, _passwordController.text);

      if (mounted) {
        if (userProvider.errorMessage == null) {
          Navigator.of(context).pop(); // Cerramos el modal
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario añadido con éxito'),
              backgroundColor: Colors.green,
            ),
          );
          
        } else {
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: ${userProvider.errorMessage}'),
              backgroundColor: Colors.red, // Color rojo para indicar error
            ),
          );
        }
      }
      
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Añadir Nuevo Usuario',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                ),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                ),
                obscureText: true,
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idSucursalController,
                      decoration: const InputDecoration(
                        labelText: 'ID Sucursal',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _idTipoController,
                      decoration: const InputDecoration(
                        labelText: 'ID Tipo',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _telefonoMovilController,
                      decoration: const InputDecoration(
                        labelText: 'Tel. Móvil',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fechaIngresoController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha Ingreso (YYYY-MM-DD)',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar Usuario',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
