// lib/screens/clientes/edit_cliente_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/models/cliente.dart';
import 'package:sist_tickets/providers/client_provider.dart';

class EditClienteScreen extends StatefulWidget {
  final Cliente cliente; // Recibe el cliente a editar

  const EditClienteScreen({
    super.key,
    required this.cliente,
  });

  @override
  State<EditClienteScreen> createState() => _EditClienteScreenState();
}

class _EditClienteScreenState extends State<EditClienteScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false; // Para el indicador de guardado

  // Controladores para cada campo del cliente
  late TextEditingController _razonSocialController;
  late TextEditingController _domicilioController;
  late TextEditingController _idLocalidadController;
  late TextEditingController _nombreLocalidadController;
  late TextEditingController _nombreProvinciaController;
  late TextEditingController _codigoPostalController;
  late TextEditingController _telefonoController;
  late TextEditingController _telefonoMovilController;
  late TextEditingController _emailController;
  late TextEditingController _cuitController;
  late TextEditingController _idTipoClienteController;

  @override
  void initState() {
    super.initState();
    // Inicializar controladores con los datos del cliente
    _razonSocialController = TextEditingController(text: widget.cliente.razonSocial ?? '');
    _domicilioController = TextEditingController(text: widget.cliente.domicilio ?? '');
    _idLocalidadController = TextEditingController(text: widget.cliente.idLocalidad?.toString() ?? '');
    _nombreLocalidadController = TextEditingController(text: widget.cliente.nombreLocalidad ?? '');
    _nombreProvinciaController = TextEditingController(text: widget.cliente.nombreProvincia ?? '');
    _codigoPostalController = TextEditingController(text: widget.cliente.codigoPostal ?? '');
    _telefonoController = TextEditingController(text: widget.cliente.telefono ?? '');
    _telefonoMovilController = TextEditingController(text: widget.cliente.telefonoMovil ?? '');
    _emailController = TextEditingController(text: widget.cliente.email ?? '');
    _cuitController = TextEditingController(text: widget.cliente.cuit ?? '');
    _idTipoClienteController = TextEditingController(text: widget.cliente.idTipoCliente?.toString() ?? '');
  }

  @override
  void dispose() {
    // Liberar los controladores
    _razonSocialController.dispose();
    _domicilioController.dispose();
    _idLocalidadController.dispose();
    _nombreLocalidadController.dispose();
    _nombreProvinciaController.dispose();
    _codigoPostalController.dispose();
    _telefonoController.dispose();
    _telefonoMovilController.dispose();
    _emailController.dispose();
    _cuitController.dispose();
    _idTipoClienteController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return; // Si el formulario no es válido, no hacer nada
    }

    setState(() {
      _isLoading = true; // Iniciar indicador de carga
    });

    // Crear el objeto Cliente actualizado
    final updatedCliente = Cliente(
      idCliente: widget.cliente.idCliente, // Mantener el ID original
      razonSocial: _razonSocialController.text,
      domicilio: _domicilioController.text.isNotEmpty ? _domicilioController.text : null,
      idLocalidad: int.tryParse(_idLocalidadController.text),
      nombreLocalidad: _nombreLocalidadController.text.isNotEmpty ? _nombreLocalidadController.text : null,
      nombreProvincia: _nombreProvinciaController.text.isNotEmpty ? _nombreProvinciaController.text : null,
      codigoPostal: _codigoPostalController.text.isNotEmpty ? _codigoPostalController.text : null,
      telefono: _telefonoController.text.isNotEmpty ? _telefonoController.text : null,
      telefonoMovil: _telefonoMovilController.text.isNotEmpty ? _telefonoMovilController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      cuit: _cuitController.text.isNotEmpty ? _cuitController.text : null,
      idTipoCliente: int.tryParse(_idTipoClienteController.text),
    );

    try {
      // Llamar al provider para actualizar el cliente
      final success = await context.read<ClientProvider>().updateClient(updatedCliente);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente actualizado con éxito.'),
              backgroundColor: kSuccessColor,
            ),
          );
          Navigator.of(context).pop(); // Volver a la pantalla anterior
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al actualizar el cliente.'),
              backgroundColor: kErrorColor,
            ),
          );
        }
      }
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Error: ${e.toString()}'),
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
        title: const Text('Editar Cliente'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          _isLoading
              ? const Padding( // Muestra el indicador de carga si está guardando
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
                controller: _razonSocialController,
                decoration: const InputDecoration(
                  labelText: 'Razón Social',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese la razón social';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _domicilioController,
                decoration: const InputDecoration(
                  labelText: 'Domicilio',
                  border: OutlineInputBorder(),
                ),
                // No es obligatorio, no necesita validator
              ),
              const SizedBox(height: 16),
              Row(
                 children: [
                   Expanded(
                     child: TextFormField(
                       controller: _nombreLocalidadController,
                       decoration: const InputDecoration(
                         labelText: 'Localidad',
                         border: OutlineInputBorder(),
                       ),
                     ),
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: TextFormField(
                       controller: _nombreProvinciaController,
                       decoration: const InputDecoration(
                         labelText: 'Provincia',
                         border: OutlineInputBorder(),
                       ),
                     ),
                   ),
                 ],
               ),
               const SizedBox(height: 16),
              TextFormField(
                controller: _codigoPostalController,
                decoration: const InputDecoration(
                  labelText: 'Código Postal',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                 children: [
                   Expanded(
                     child: TextFormField(
                       controller: _telefonoController,
                       decoration: const InputDecoration(
                         labelText: 'Teléfono Fijo',
                         border: OutlineInputBorder(),
                       ),
                       keyboardType: TextInputType.phone,
                     ),
                   ),
                   const SizedBox(width: 8),
                   Expanded(
                     child: TextFormField(
                       controller: _telefonoMovilController,
                       decoration: const InputDecoration(
                         labelText: 'Teléfono Móvil',
                         border: OutlineInputBorder(),
                       ),
                       keyboardType: TextInputType.phone,
                     ),
                   ),
                 ],
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
                controller: _cuitController,
                decoration: const InputDecoration(
                  labelText: 'CUIT',
                  border: OutlineInputBorder(),
                ),
              ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _idLocalidadController,
                 decoration: const InputDecoration(
                   labelText: 'ID Localidad (Opcional)',
                   border: OutlineInputBorder(),
                 ),
                 keyboardType: TextInputType.number,
               ),
               const SizedBox(height: 16),
               TextFormField(
                 controller: _idTipoClienteController,
                 decoration: const InputDecoration(
                   labelText: 'ID Tipo Cliente (Opcional)',
                   border: OutlineInputBorder(),
                 ),
                 keyboardType: TextInputType.number,
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