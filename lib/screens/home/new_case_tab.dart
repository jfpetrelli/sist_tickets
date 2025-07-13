import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/api/api_service.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/models/cliente.dart';
import 'package:sist_tickets/models/ticket.dart';
import 'package:sist_tickets/models/usuario.dart';
import 'package:sist_tickets/providers/client_provider.dart';
import 'package:sist_tickets/providers/user_list_provider.dart';
import 'package:sist_tickets/providers/user_provider.dart';

class NewCaseTab extends StatefulWidget {
  const NewCaseTab({super.key});

  @override
  State<NewCaseTab> createState() => _NewCaseTabState();
}

class _NewCaseTabState extends State<NewCaseTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  // Variables para guardar la selección del formulario
  int? _selectedClientId;
  int? _selectedCaseTypeId; // Para el tipo de caso
  int? _selectedPriorityId; // Para la prioridad
  int? _selectedAssignedTechnicianId; // Para el técnico asignado
  DateTime? _selectedTentativeDate; // Para la fecha tentativa
  bool _isSaving = false;

  Future<void> _selectTentativeDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedTentativeDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(_selectedTentativeDate ?? DateTime.now()),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedTentativeDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _saveCase() async {
    // Valida que el formulario esté completo
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true; // Inicia el estado de carga
    });

    // Obtiene el ID del usuario que está creando el caso
    final creatorId = context.read<UserProvider>().user?.idPersonal;
    if (creatorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: No se pudo identificar al usuario creador.')),
      );
      setState(() {
        _isSaving = false;
      });
      return;
    }

    // Prepara los datos del ticket para enviar
    final newTicket = Ticket(
      fecha: DateTime.now(),
      titulo: _titleController.text,
      idCliente: _selectedClientId!,
      idPersonalCreador: creatorId,
      idPersonalAsignado: _selectedAssignedTechnicianId!,
      idTipocaso: _selectedCaseTypeId!,
      idEstado: 1, // Estado "Pendiente"
      idPrioridad: _selectedPriorityId!,
      ultimaModificacion: DateTime.now(),
      fechaTentativaInicio: _selectedTentativeDate,
      // Los campos opcionales que no tenemos se omiten
    );
    final ticketData = newTicket.toJson();

    try {
      await context.read<ApiService>().createTicket(ticketData);

      // Muestra mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kSuccessColor,
          content: Text('¡Caso creado exitosamente!'),
        ),
      );

      // Limpia el formulario para el próximo caso
      _formKey.currentState?.reset();
      setState(() {
        _titleController.clear();
        _selectedClientId = null;
        _selectedCaseTypeId = null;
        _selectedPriorityId = null;
        _selectedAssignedTechnicianId = null;
        _selectedTentativeDate = null;
      });
    } catch (e) {
      // Muestra mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el caso: $e')),
      );
    } finally {
      // Detiene el estado de carga
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Usamos addPostFrameCallback para asegurar que el context esté disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Pedimos al provider que cargue los clientes al iniciar la pantalla
      context.read<ClientProvider>().fetchClients();
      context.read<UserListProvider>().fetchUsers(userType: 1);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nuevo Caso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Usamos un Consumer para escuchar los cambios en ClientProvider
            Consumer<ClientProvider>(
              builder: (context, clientProvider, child) {
                if (clientProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (clientProvider.errorMessage != null) {
                  return Center(
                    child: Text(
                      clientProvider.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                return DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _selectedClientId,
                  decoration: InputDecoration(
                    labelText: 'Cliente',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.business),
                  ),
                  // Generamos los items del dropdown a partir de la lista de clientes
                  items: clientProvider.clients.map((Cliente client) {
                    return DropdownMenuItem<int>(
                      value: client.idCliente,
                      child: Text(client.razonSocial ?? 'Nombre no disponible',
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClientId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor, seleccione un cliente';
                    }
                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingrese un título';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _selectedCaseTypeId,
              decoration: const InputDecoration(
                labelText: 'Tipo de Caso',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                // Usaremos valores fijos por ahora. El 'value' es el ID.
                DropdownMenuItem(value: 1, child: Text('Instalación')),
                DropdownMenuItem(value: 2, child: Text('Reparación')),
                DropdownMenuItem(value: 3, child: Text('Mantenimiento')),
                DropdownMenuItem(value: 4, child: Text('Consulta')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCaseTypeId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor, seleccione un tipo de caso';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              value: _selectedPriorityId,
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: const [
                // Usaremos valores fijos por ahora. El 'value' es el ID.
                DropdownMenuItem(value: 1, child: Text('Alta')),
                DropdownMenuItem(value: 2, child: Text('Media')),
                DropdownMenuItem(value: 3, child: Text('Baja')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPriorityId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor, seleccione una prioridad';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // --- Campo para Técnico Asignado ---
            Consumer<UserListProvider>(
              builder: (context, userListProvider, child) {
                if (userListProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return DropdownButtonFormField<int>(
                  value: _selectedAssignedTechnicianId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Técnico Asignado',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: userListProvider.users.map((Usuario user) {
                    // Usa la lista de usuarios
                    return DropdownMenuItem<int>(
                      value: user.idPersonal,
                      child: Text(
                        user.nombre,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedAssignedTechnicianId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor, asigne un técnico';
                    }
                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // --- Campo para Fecha Tentativa ---
            TextFormField(
              readOnly:
                  true, // El campo es de solo lectura, se edita con el picker
              onTap: _selectTentativeDate,
              decoration: InputDecoration(
                labelText: 'Fecha Tentativa de Inicio',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              // Muestra la fecha formateada si ha sido seleccionada
              controller: TextEditingController(
                text: _selectedTentativeDate != null
                    ? DateFormat('dd/MM/yyyy HH:mm')
                        .format(_selectedTentativeDate!)
                    : '',
              ),
              validator: (value) {
                if (_selectedTentativeDate == null) {
                  return 'Por favor, seleccione una fecha';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                // Llama a la nueva función. Se deshabilita si ya se está guardando.
                onPressed: _isSaving ? null : _saveCase,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar Caso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
