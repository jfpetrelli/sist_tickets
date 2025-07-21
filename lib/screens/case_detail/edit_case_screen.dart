import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/models/ticket.dart';
import 'package:sist_tickets/models/usuario.dart';
import 'package:sist_tickets/providers/ticket_provider.dart';
import 'package:sist_tickets/providers/user_list_provider.dart';

class EditCaseScreen extends StatefulWidget {
  final String caseId;

  const EditCaseScreen({
    super.key,
    required this.caseId,
  });

  @override
  State<EditCaseScreen> createState() => _EditCaseScreenState();
}

class _EditCaseScreenState extends State<EditCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;

  Ticket? _ticket;
  bool _isLoading = true;
  bool _isSaving = false;
  int? _selectedCaseTypeId;
  int? _selectedPriorityId;
  int? _selectedAssignedTechnicianId;
  DateTime? _selectedTentativeDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final userListProvider =
        Provider.of<UserListProvider>(context, listen: false);

    await userListProvider.fetchUsers(userType: 1);
    await ticketProvider.getTicketById(widget.caseId);

    if (mounted && ticketProvider.ticket != null) {
      setState(() {
        _ticket = ticketProvider.ticket;
        _titleController.text = _ticket!.titulo;
        _selectedCaseTypeId = _ticket!.idTipocaso;
        _selectedPriorityId = _ticket!.idPrioridad;
        _selectedAssignedTechnicianId = _ticket!.idPersonalAsignado;
        _selectedTentativeDate = _ticket!.fechaTentativaInicio;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se pudo cargar el ticket.')),
      );
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedTicket = Ticket(
      idCaso: _ticket!.idCaso,
      titulo: _titleController.text,
      idCliente: _ticket!.idCliente,
      idPersonalCreador: _ticket!.idPersonalCreador,
      idPersonalAsignado: _selectedAssignedTechnicianId!,
      idTipocaso: _selectedCaseTypeId!,
      idEstado: _ticket!.idEstado,
      idPrioridad: _selectedPriorityId!,
      fechaTentativaInicio: _selectedTentativeDate,
      fecha: _ticket!.fecha,
      ultimaModificacion: DateTime.now(),
    );

    final success = await context
        .read<TicketProvider>()
        .updateTicket(widget.caseId, updatedTicket);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Caso actualizado con éxito.'),
            backgroundColor: kSuccessColor,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el caso.'),
            backgroundColor: kErrorColor,
          ),
        );
      }
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTentativeDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedTentativeDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Caso'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          _isSaving
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ticket == null
              ? const Center(child: Text('No se encontró el ticket.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cliente: ${_ticket?.cliente?.razonSocial ?? "N/A"}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),

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
                            DropdownMenuItem(
                                value: 1, child: Text('Instalación')),
                            DropdownMenuItem(
                                value: 2, child: Text('Reparación')),
                            DropdownMenuItem(
                                value: 3, child: Text('Mantenimiento')),
                            DropdownMenuItem(value: 4, child: Text('Consulta')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedCaseTypeId = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Seleccione un tipo' : null,
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
                            DropdownMenuItem(value: 1, child: Text('Alta')),
                            DropdownMenuItem(value: 2, child: Text('Media')),
                            DropdownMenuItem(value: 3, child: Text('Baja')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedPriorityId = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Seleccione una prioridad' : null,
                        ),
                        const SizedBox(height: 16),

                        Consumer<UserListProvider>(
                          builder: (context, userListProvider, child) {
                            final technicianExists = userListProvider.users.any(
                                (user) =>
                                    user.idPersonal ==
                                    _selectedAssignedTechnicianId);

                            return DropdownButtonFormField<int>(
                              value: technicianExists
                                  ? _selectedAssignedTechnicianId
                                  : null,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Técnico Asignado',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              items: userListProvider.users.map((Usuario user) {
                                return DropdownMenuItem<int>(
                                  value: user.idPersonal,
                                  child: Text(user.nombre,
                                      overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedAssignedTechnicianId = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Asigne un técnico' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          readOnly: true,
                          onTap: _selectTentativeDate,
                          decoration: InputDecoration(
                            labelText: 'Fecha Tentativa de Inicio',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: _selectedTentativeDate != null
                                ? DateFormat('dd/MM/yyyy HH:mm')
                                    .format(_selectedTentativeDate!)
                                : '',
                          ),
                        ),
                        const SizedBox(height: 24), // Espacio antes del botón

                        // --- NUEVO BOTÓN DE GUARDAR ---
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveChanges,
                            icon: _isSaving
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
