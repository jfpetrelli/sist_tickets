import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/models/ticket.dart';
import 'package:sist_tickets/models/usuario.dart';
import 'package:sist_tickets/providers/ticket_provider.dart';
import 'package:sist_tickets/providers/user_list_provider.dart';
import 'package:sist_tickets/providers/tipos_caso_provider.dart';
import 'package:sist_tickets/providers/user_provider.dart';
import 'package:sist_tickets/models/intervencion_ticket.dart';

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
  late TextEditingController _telefonoContactoController;

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
    _telefonoContactoController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final ticketProvider = Provider.of<TicketProvider>(context, listen: false);
    final userListProvider =
        Provider.of<UserListProvider>(context, listen: false);
    final tiposCasoProvider =
        Provider.of<TiposCasoProvider>(context, listen: false);

    await tiposCasoProvider.fetchTiposCaso();

    await userListProvider.fetchUsers(userType: 1);
    await ticketProvider.getTicketById(widget.caseId);

    if (mounted && ticketProvider.ticket != null) {
      setState(() {
        _ticket = ticketProvider.ticket;
        _titleController.text = _ticket!.titulo;
        _telefonoContactoController.text = _ticket!.telefonoContacto ?? '';
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

    // Validación informativa: técnico con ticket activo en el rango de 1 hora desde la fecha tentativa
    final ticketsProvider = context.read<TicketProvider>();
    final List<Ticket> tickets = ticketsProvider.tickets;
    final int? tecnicoId = _selectedAssignedTechnicianId;
    final DateTime? fechaTentativa = _selectedTentativeDate;
    final conflictTickets = tickets.where((t) {
      if (t.idCaso == _ticket?.idCaso) return false; // Ignorar el ticket actual
      if (t.idPersonalAsignado != tecnicoId) return false;
      if (!(t.idEstado == 1 || t.idEstado == 2)) return false;
      if (t.fechaTentativaInicio == null || fechaTentativa == null)
        return false;
      // Rango de 1 hora desde la fecha tentativa
      final start = fechaTentativa.subtract(const Duration(hours: 1));
      final end = fechaTentativa.add(const Duration(hours: 1));
      return t.fechaTentativaInicio!.isAfter(start) &&
          t.fechaTentativaInicio!.isBefore(end);
      // Comentario: aquí se podría implementar lógica de solapamiento en el futuro
    }).toList();

    bool continueSave = true;
    if (conflictTickets.isNotEmpty) {
      final ticketIds =
          conflictTickets.map((t) => t.idCaso?.toString() ?? '-').toList();
      continueSave = await showDialog<bool>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: const Text('Advertencia de asignación'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text(
                          'El técnico seleccionado ya tiene ${conflictTickets.length} ticket(s) activo(s) asignado(s) en el rango de 1 hora desde la fecha/hora elegida.'),
                      const SizedBox(height: 8),
                      const Text('Tickets:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: ticketIds
                            .map((id) => Chip(label: Text(id)))
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      const Text('¿Desea continuar con la asignación?'),
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
                    child: const Text('Continuar'),
                  ),
                ],
              );
            },
          ) ??
          false;
    }
    if (!continueSave) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    final prevTechnicianId = _ticket!.idPersonalAsignado;
    final userListProvider = context.read<UserListProvider>();
    final prevTechnician = userListProvider.users.firstWhere(
      (u) => u.idPersonal == prevTechnicianId,
      orElse: () => Usuario(
        idPersonal: prevTechnicianId,
        idSucursal: 0,
        idTipo: 1,
        activo: true,
        nombre: 'Desconocido',
      ),
    );
    final newTechnician = userListProvider.users.firstWhere(
      (u) => u.idPersonal == _selectedAssignedTechnicianId,
      orElse: () => Usuario(
        idPersonal: _selectedAssignedTechnicianId ?? 0,
        idSucursal: 0,
        idTipo: 1,
        activo: true,
        nombre: 'Desconocido',
      ),
    );

    final updatedTicket = Ticket(
      idCaso: _ticket!.idCaso,
      titulo: _titleController.text,
      descripcion: _ticket!.descripcion,
      idCliente: _ticket!.idCliente,
      idPersonalCreador: _ticket!.idPersonalCreador,
      idPersonalAsignado: _selectedAssignedTechnicianId!,
      telefonoContacto: _telefonoContactoController.text.isNotEmpty
          ? _telefonoContactoController.text
          : null,
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

    // Si cambió el técnico asignado, crear intervención automática
    if (prevTechnicianId != _selectedAssignedTechnicianId) {
      final userProvider = context.read<UserProvider>();
      final usuario = userProvider.user;
      final now = DateTime.now();
      final detalleMsg =
          'Cambio de técnico asignado: ${prevTechnician.nombre} → ${newTechnician.nombre}';
      final intervencion = TicketIntervencion(
        idCaso: _ticket!.idCaso,
        idIntervencion: null,
        fechaVencimiento: now, // El modelo requiere DateTime
        fecha: now,
        idTipoIntervencion: 4, // Actualización de datos
        detalle: detalleMsg,
        tiempoUtilizado: 0, // null no permitido, se usa 0
        idContacto: usuario?.idPersonal.toString() ?? '',
      );
      await context
          .read<TicketProvider>()
          .addIntervencion(_ticket!.idCaso!, intervencion);
    }

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
    _telefonoContactoController.dispose();
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

                        TextFormField(
                          initialValue: _ticket!.descripcion,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.description),
                          ),
                          onChanged: (value) {
                            // Actualizar la descripción en el ticket
                            _ticket = Ticket(
                              idCaso: _ticket!.idCaso,
                              titulo: _ticket!.titulo,
                              descripcion: value,
                              idCliente: _ticket!.idCliente,
                              idPersonalCreador: _ticket!.idPersonalCreador,
                              idPersonalAsignado: _ticket!.idPersonalAsignado,
                              idTipocaso: _ticket!.idTipocaso,
                              idEstado: _ticket!.idEstado,
                              idPrioridad: _ticket!.idPrioridad,
                              telefonoContacto: _ticket!.telefonoContacto,
                              fecha: _ticket!.fecha,
                              ultimaModificacion: _ticket!.ultimaModificacion,
                              fechaTentativaInicio:
                                  _ticket!.fechaTentativaInicio,
                              fechaTentativaFinalizacion:
                                  _ticket!.fechaTentativaFinalizacion,
                              cliente: _ticket!.cliente,
                              intervenciones: _ticket!.intervenciones,
                              tecnico: _ticket!.tecnico,
                            );
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingrese una descripción';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _telefonoContactoController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono de contacto (opcional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),

                        Consumer<TiposCasoProvider>(
                          builder: (context, tiposCasoProvider, child) {
                            if (tiposCasoProvider.isLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (tiposCasoProvider.errorMessage != null) {
                              return Text(
                                tiposCasoProvider.errorMessage ?? '',
                                style: const TextStyle(color: Colors.red),
                              );
                            }

                            // Eliminar duplicados usando un Map
                            final Map<int, dynamic> uniqueTipos = {};
                            for (var tipo in tiposCasoProvider.tiposCaso) {
                              uniqueTipos[tipo.id] = tipo;
                            }
                            final uniqueTiposList = uniqueTipos.values.toList();

                            return DropdownButtonFormField<int>(
                              value: _selectedCaseTypeId,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Caso',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.category),
                              ),
                              items: uniqueTiposList
                                  .map((tipo) => DropdownMenuItem<int>(
                                        value: tipo.id,
                                        child: Text(tipo.nombre),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCaseTypeId = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Seleccione un tipo' : null,
                            );
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

                        Consumer2<UserListProvider, UserProvider>(
                          builder:
                              (context, userListProvider, userProvider, child) {
                            if (userListProvider.isLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final currentUser = userProvider.user;
                            List<Usuario> availableUsers;

                            // Si el usuario es tipo 1 (técnico), solo puede asignarse a sí mismo
                            if (currentUser?.idTipo == 1) {
                              availableUsers =
                                  currentUser != null ? [currentUser] : [];
                              // Auto-seleccionar al usuario actual si no hay una selección previa
                              if (_selectedAssignedTechnicianId == null &&
                                  currentUser != null) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  setState(() {
                                    _selectedAssignedTechnicianId =
                                        currentUser.idPersonal;
                                  });
                                });
                              }
                            } else {
                              // Si es tipo 2 (administrador), mostrar todos los técnicos
                              // Eliminar duplicados por idPersonal
                              final Map<int, Usuario> uniqueUsers = {};
                              for (var user in userListProvider.users) {
                                uniqueUsers[user.idPersonal] = user;
                              }
                              availableUsers = uniqueUsers.values.toList();
                            }

                            return FormField<String>(
                              validator: (value) {
                                if (_selectedAssignedTechnicianId == null) {
                                  return 'Asigne un técnico';
                                }
                                return null;
                              },
                              builder: (FormFieldState<String> state) {
                                return Autocomplete<Usuario>(
                                  displayStringForOption: (Usuario user) =>
                                      user.nombre,
                                  optionsBuilder:
                                      (TextEditingValue textEditingValue) {
                                    if (textEditingValue.text.isEmpty) {
                                      return const Iterable<Usuario>.empty();
                                    }
                                    return availableUsers.where((Usuario user) {
                                      return user.nombre.toLowerCase().contains(
                                          textEditingValue.text.toLowerCase());
                                    });
                                  },
                                  onSelected: (Usuario selection) {
                                    setState(() {
                                      _selectedAssignedTechnicianId =
                                          selection.idPersonal;
                                      state.didChange(selection.nombre);
                                    });
                                  },
                                  fieldViewBuilder: (context, controller,
                                      focusNode, onSubmitted) {
                                    // Solo inicializar el valor del controller si está vacío y hay una selección
                                    if (controller.text.isEmpty &&
                                        _selectedAssignedTechnicianId != null) {
                                      final selectedUser =
                                          availableUsers.firstWhere(
                                              (u) =>
                                                  u.idPersonal ==
                                                  _selectedAssignedTechnicianId,
                                              orElse: () =>
                                                  availableUsers.isNotEmpty
                                                      ? availableUsers.first
                                                      : Usuario(
                                                          idPersonal: 0,
                                                          idSucursal: 0,
                                                          idTipo: 0,
                                                          nombre: '',
                                                          activo: false));
                                      controller.text = selectedUser.nombre;
                                    }
                                    controller.addListener(() {
                                      if (_selectedAssignedTechnicianId !=
                                              null &&
                                          controller.text !=
                                              availableUsers
                                                  .firstWhere(
                                                      (u) =>
                                                          u.idPersonal ==
                                                          _selectedAssignedTechnicianId,
                                                      orElse: () =>
                                                          availableUsers
                                                                  .isNotEmpty
                                                              ? availableUsers
                                                                  .first
                                                              : Usuario(
                                                                  idPersonal: 0,
                                                                  idSucursal: 0,
                                                                  idTipo: 0,
                                                                  nombre: '',
                                                                  activo:
                                                                      false))
                                                  .nombre) {
                                        setState(() {
                                          _selectedAssignedTechnicianId = null;
                                          state.didChange(null);
                                        });
                                      }
                                    });
                                    return TextFormField(
                                      controller: controller,
                                      focusNode: focusNode,
                                      decoration: InputDecoration(
                                        labelText: 'Técnico Asignado',
                                        border: const OutlineInputBorder(),
                                        prefixIcon: const Icon(Icons.person),
                                        helperText: currentUser?.idTipo == 1
                                            ? 'Solo puedes asignarte casos a ti mismo'
                                            : null,
                                        errorText: state.errorText,
                                      ),
                                    );
                                  },
                                );
                              },
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 200,
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
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
