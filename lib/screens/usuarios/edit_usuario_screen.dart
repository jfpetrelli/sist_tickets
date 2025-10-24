// lib/screens/usuarios/edit_usuario_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/constants.dart';
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
  DateTime? _fechaEgreso;

  // Formateador de fecha
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con los datos del usuario
    _nombreController = TextEditingController(text: widget.usuario.nombre);
    _telefonoMovilController = TextEditingController(text: widget.usuario.telefonoMovil ?? '');
    _emailController = TextEditingController(text: widget.usuario.email ?? '');
    _idSucursalController = TextEditingController(text: widget.usuario.idSucursal.toString());
    _idTipoController = TextEditingController(text: widget.usuario.idTipo.toString());
    _fechaIngreso = widget.usuario.fechaIngreso;
    _fechaEgreso = widget.usuario.fechaEgreso;
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

  // --- Selección de Fecha ---
  Future<void> _selectDate(BuildContext context, bool isIngreso) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isIngreso ? _fechaIngreso : _fechaEgreso) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isIngreso ? _fechaIngreso : _fechaEgreso)) {
      setState(() {
        if (isIngreso) {
          _fechaIngreso = picked;
        } else {
          _fechaEgreso = picked;
        }
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
      telefonoMovil: _telefonoMovilController.text.isNotEmpty ? _telefonoMovilController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      idSucursal: int.tryParse(_idSucursalController.text) ?? widget.usuario.idSucursal,
      idTipo: int.tryParse(_idTipoController.text) ?? widget.usuario.idTipo,
      fechaIngreso: _fechaIngreso,
      fechaEgreso: _fechaEgreso,
      profilePhotoUrl: widget.usuario.profilePhotoUrl, // Mantener URL de foto existente
    );

    try {

      final success = await context.read<UserListProvider>().updateUser(updatedUsuario);

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
              content: Text(context.read<UserListProvider>().errorMessage ?? 'Error al actualizar el usuario.'),
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
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
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
                       }
                    ),
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
                       }
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // --- Campos de Fecha ---
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
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                         decoration: InputDecoration(
                           labelText: 'Fecha Egreso',
                           border: const OutlineInputBorder(),
                         ),
                         child: Text(
                           _fechaEgreso != null
                             ? _dateFormatter.format(_fechaEgreso!)
                             : 'Opcional...',
                           style: TextStyle(
                             fontSize: 16,
                             color: _fechaEgreso == null ? Colors.grey[600] : null,
                           ),
                         ),
                       ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // --- Botón de Guardar ---
              SizedBox(
                width: double.infinity,
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
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}