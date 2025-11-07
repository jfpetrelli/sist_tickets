// lib/screens/usuarios/edit_usuario_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/api/api_service.dart';
import 'package:sist_tickets/models/usuario.dart'; // Modelo de Usuario
import 'package:sist_tickets/providers/user_list_provider.dart'; // Provider de Usuarios
import 'package:intl/intl.dart'; // Para formatear fechas

class EditUsuarioScreen extends StatefulWidget {
  final Usuario usuario; // Recibe el usuario a editar

  const EditUsuarioScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<EditUsuarioScreen> createState() => _EditUsuarioScreenState();
}

class _EditUsuarioScreenState extends State<EditUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores para cada campo del usuario
  late TextEditingController _nombreController;
  late TextEditingController _telefonoMovilController;
  late TextEditingController _emailController;
  late TextEditingController _idSucursalController;
  late TextEditingController _idTipoController;
  DateTime? _fechaIngreso; // Usamos DateTime? para el DatePicker
  bool _activo = true; // Toggle de estado activo (1/0)
  DateTime? _fechaEgreso; // Se carga automáticamente al desactivar

  // Formateador de fecha
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con los datos del usuario
    _nombreController = TextEditingController(text: widget.usuario.nombre);
    _telefonoMovilController =
        TextEditingController(text: widget.usuario.telefonoMovil ?? '');
    _emailController = TextEditingController(text: widget.usuario.email ?? '');
    _idSucursalController =
        TextEditingController(text: widget.usuario.idSucursal.toString());
    _idTipoController =
        TextEditingController(text: widget.usuario.idTipo.toString());
    _fechaIngreso = widget.usuario.fechaIngreso;
    _fechaEgreso = widget.usuario.fechaEgreso;
    _activo = widget.usuario.activo == true;
  }

  @override
  void dispose() {
    // Liberar los controladores
    _nombreController.dispose();
    _telefonoMovilController.dispose();
    _emailController.dispose();
    _idSucursalController.dispose();
    _idTipoController.dispose();
    super.dispose();
  }

  Future<void> _onActivoChanged(bool val) async {
    // If trying to deactivate, check for active tickets assigned to this user
    if (!val) {
      try {
        final api = ApiService();
        // Use API filter to request tickets assigned to this user only
        final tickets =
            await api.getTickets(widget.usuario.idPersonal.toString());

        final activeTickets = tickets.where((t) {
          if (t is Map) {
            final idAsignado =
                t['id_personal_asignado'] ?? t['idPersonalAsignado'];
            final idEstado = t['id_estado'] ?? t['idEstado'];
            return idAsignado == widget.usuario.idPersonal &&
                (idEstado == 1 || idEstado == 2);
          }
          return false;
        }).toList();

        if (activeTickets.isNotEmpty) {
          // Prepare ticket IDs list
          final ticketIds = activeTickets.map((t) {
            if (t is Map) return t['id_caso'] ?? t['idCaso'] ?? t['id'] ?? '-';
            return '-';
          }).toList();

          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Advertencia'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text(
                          'El usuario tiene ${activeTickets.length} ticket(s) activo(s).'),
                      const SizedBox(height: 8),
                      const Text('Tickets activos:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ticketIds
                            .map((id) => Chip(label: Text(id.toString())))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                          '¿Está seguro que desea dar de baja al usuario?'),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Dar de baja'),
                  ),
                ],
              );
            },
          );

          if (confirmed == true) {
            setState(() {
              _activo = false;
              _fechaEgreso = DateTime.now();
            });
          } else {
            // keep as it was
            setState(() {
              _activo = true;
            });
          }
          return;
        }

        // No active tickets -> allow deactivate
        setState(() {
          _activo = false;
          _fechaEgreso = DateTime.now();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Error al verificar tickets activos: ${e.toString()}')),
          );
        }
      }
    } else {
      // Activating -> clear fechaEgreso
      setState(() {
        _activo = true;
        _fechaEgreso = null;
      });
    }
  }

  // --- Selección de Fecha ---
  Future<void> _selectDate(BuildContext context, bool isIngreso) async {
    // Solo manejamos fecha de ingreso, el parámetro se mantiene para mínima intrusión
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fechaIngreso) {
      setState(() {
        _fechaIngreso = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return; // Si el formulario no es válido, no hacer nada
    }

    setState(() {
      _isLoading = true; // Iniciar indicador de carga
    });

    // Crear el objeto Usuario actualizado
    final updatedUsuario = Usuario(
      idPersonal: widget.usuario.idPersonal, // Mantener el ID original
      nombre: _nombreController.text,
      telefonoMovil: _telefonoMovilController.text.isNotEmpty
          ? _telefonoMovilController.text
          : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      idSucursal:
          int.tryParse(_idSucursalController.text) ?? widget.usuario.idSucursal,
      idTipo: int.tryParse(_idTipoController.text) ?? widget.usuario.idTipo,
      fechaIngreso: _fechaIngreso,
      // Si el usuario pasa de activo a inactivo, cargar fecha de egreso = NOW
      // Si ya estaba inactivo o pasa a activo, mantener el valor existente
      fechaEgreso: _fechaEgreso,
      profilePhotoUrl:
          widget.usuario.profilePhotoUrl, // Mantener URL de foto existente
      activo: _activo,
    );

    try {
      final success =
          await context.read<UserListProvider>().updateUser(updatedUsuario);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario actualizado con éxito.'), // Mensaje real
              backgroundColor: kSuccessColor,
            ),
          );
          Navigator.of(context).pop(); // Volver a la pantalla anterior
        } else {
          // Si falla, mostramos el error que guardó el provider
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.read<UserListProvider>().errorMessage ??
                  'Error al actualizar el usuario.'),
              backgroundColor: kErrorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${e.toString()}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Detener indicador de carga
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Resetear Contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '¿Está seguro que desea resetear la contraseña de ${_nombreController.text}?'),
              const SizedBox(height: 12),
              const Text(
                'El usuario deberá cambiar su contraseña en el próximo inicio de sesión.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('Resetear'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Proceder con el reseteo de contraseña
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context
          .read<UserListProvider>()
          .resetUserPassword(widget.usuario.idPersonal);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contraseña reseteada exitosamente.'),
              backgroundColor: kSuccessColor,
            ),
          );
        } else {
          final err = context.read<UserListProvider>().errorMessage ??
              'Error al resetear la contraseña';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: kErrorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al resetear contraseña: ${e.toString()}'),
            backgroundColor: kErrorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuario'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.save),
                  tooltip: 'Guardar Cambios',
                  onPressed: _saveChanges,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Campos del Formulario ---
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese el nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null &&
                      value.isNotEmpty &&
                      !value.contains('@')) {
                    return 'Ingrese un email válido';
                  }
                  return null; // Email es opcional pero si se ingresa, debe ser válido
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonoMovilController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono Móvil',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                        controller: _idSucursalController,
                        decoration: const InputDecoration(
                          labelText: 'ID Sucursal',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                        controller: _idTipoController,
                        decoration: const InputDecoration(
                          labelText: 'ID Tipo',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // --- Campo de Fecha de Ingreso y estado Activo ---
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha Ingreso',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _fechaIngreso != null
                              ? _dateFormatter.format(_fechaIngreso!)
                              : 'Seleccionar...',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: const Text('Activo'),
                      value: _activo,
                      onChanged: (val) => _onActivoChanged(val),
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // --- Botones de acción (responsive) ---
              SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _resetPassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Resetear Contraseña'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveChanges,
                        icon: _isLoading
                            ? Container(
                                width: 24,
                                height: 24,
                                padding: const EdgeInsets.all(2.0),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Guardar Cambios'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
