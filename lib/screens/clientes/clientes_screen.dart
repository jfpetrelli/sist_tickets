// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/client_provider.dart';
import '../../models/cliente.dart';
import 'edit_cliente_screen.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  void _showAddClienteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) {
        return const _AddClienteForm();
      },
    );
  }

  Future<void> _refreshClientes() async {
    await Provider.of<ClientProvider>(context, listen: false).fetchClients();
  }

  // --- NUEVA FUNCIÓN DE NAVEGACIÓN ---
  void _navigateToEditCliente(BuildContext context, Cliente cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Pasa el cliente a la nueva pantalla
        builder: (context) => EditClienteScreen(cliente: cliente),
      ),
    ).then((_) {
      _refreshClientes();
    });
  }

  String _search = '';
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<ClientProvider>(context, listen: false).fetchClients());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ClientProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null && provider.clients.isEmpty) {
            return Center(child: Text(provider.errorMessage!));
          }
          final clientesFiltrados = provider.clients
              .where((c) => (c.razonSocial ?? '')
                  .toLowerCase()
                  .contains(_search.toLowerCase()))
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar cliente...',
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
                  onRefresh: _refreshClientes,
                  child: clientesFiltrados.isEmpty
                      ? const Center(
                          child: Text('No hay clientes para mostrar.'))
                      : ListView.separated(
                          itemCount: clientesFiltrados.length,
                          separatorBuilder: (context, i) =>
                              const SizedBox(height: 8),
                          padding: const EdgeInsets.all(12),
                          itemBuilder: (context, index) {
                            final Cliente cliente = clientesFiltrados[index];
                            final bool isActive = cliente.activo == true;

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
                                      Icons.business,
                                      color: isActive
                                          ? Colors.blueAccent
                                          : Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    cliente.razonSocial ?? 'Sin nombre',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      decoration: isActive
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      cliente.domicilio,
                                      cliente.nombreLocalidad,
                                      cliente.nombreProvincia
                                    ]
                                        .where((e) => e != null && e.isNotEmpty)
                                        .join(', '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isActive
                                          ? Colors.black54
                                          : Colors.black38,
                                    ),
                                  ),
                                  trailing: cliente.cuit != null
                                      ? Text(
                                          cliente.cuit!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isActive
                                                ? Colors.black87
                                                : Colors.black45,
                                          ),
                                        )
                                      : null,

                                  // --- MODIFICACIÓN: ACCIÓN AL TOCAR ---
                                  onTap: () {
                                    _navigateToEditCliente(context, cliente);
                                  },
                                  // --- FIN DE LA MODIFICACIÓN ---
                                ),
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
        heroTag: 'fab_add_cliente',
        shape: const CircleBorder(),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 6,
        onPressed: () {
          _showAddClienteModal(context);
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        tooltip: 'Agregar cliente',
      ),
    );
  }
}

// Formulario para agregar un nuevo cliente (sin cambios)
class _AddClienteForm extends StatefulWidget {
  const _AddClienteForm();

  @override
  State<_AddClienteForm> createState() => __AddClienteFormState();
}

class __AddClienteFormState extends State<_AddClienteForm> {
  final _formKey = GlobalKey<FormState>();
  final _razonSocialController = TextEditingController();
  final _domicilioController = TextEditingController();
  final _idLocalidadController = TextEditingController();
  final _nombreLocalidadController = TextEditingController();
  final _nombreProvinciaController = TextEditingController();
  final _codigoPostalController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _telefonoMovilController = TextEditingController();
  final _emailController = TextEditingController();
  final _cuitController = TextEditingController();
  final _idTipoClienteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
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

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      
      final nuevoCliente = Cliente(
        idCliente: DateTime.now().millisecondsSinceEpoch,
        razonSocial: _razonSocialController.text,
        domicilio: _domicilioController.text,
        idLocalidad: int.tryParse(_idLocalidadController.text),
        nombreLocalidad: _nombreLocalidadController.text,
        nombreProvincia: _nombreProvinciaController.text,
        codigoPostal: _codigoPostalController.text,
        telefono: _telefonoController.text,
        telefonoMovil: _telefonoMovilController.text,
        email: _emailController.text,
        cuit: _cuitController.text,
        idTipoCliente: int.tryParse(_idTipoClienteController.text),
      );

      // 1. Referencia al provider
      final clientProvider = Provider.of<ClientProvider>(context, listen: false);
      
      // 2. Ejecutar 
      await clientProvider.addClient(nuevoCliente);
      
      if (mounted) {
        if (clientProvider.errorMessage == null) {
          // --- ÉXITO ---
          Navigator.of(context).pop(); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente añadido con éxito'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // --- ERROR ---
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${clientProvider.errorMessage}'),
              backgroundColor: Colors.red,
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
              Text('Añadir Nuevo Cliente',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 18),
              // Razón Social (fila completa)
              TextFormField(
                controller: _razonSocialController,
                decoration: const InputDecoration(
                  labelText: 'Razón Social',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                ),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 10),
              // Domicilio + Código Postal
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _domicilioController,
                      decoration: const InputDecoration(
                        labelText: 'Domicilio',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _codigoPostalController,
                      decoration: const InputDecoration(
                        labelText: 'Cód. Postal',
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
              // Localidad + Provincia
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nombreLocalidadController,
                      decoration: const InputDecoration(
                        labelText: 'Localidad',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Teléfono + Teléfono Móvil
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      ),
                      keyboardType: TextInputType.phone,
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
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Email + CUIT
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
                      controller: _cuitController,
                      decoration: const InputDecoration(
                        labelText: 'CUIT',
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
                      : const Text('Guardar Cliente',
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
