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
import 'package:sist_tickets/providers/tipos_caso_provider.dart';
import 'package:sist_tickets/providers/ticket_provider.dart';

class NewCaseTab extends StatefulWidget {
  const NewCaseTab({super.key});

  @override
  State<NewCaseTab> createState() => _NewCaseTabState();
}

class _NewCaseTabState extends State<NewCaseTab> {
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _clientController = TextEditingController();
  var _autoCompleteKey = UniqueKey(); // Key for the Autocomplete widget

  // Variables para guardar la selección del formulario
  int? _selectedClientId;
  int? _selectedCaseTypeId; // Para el tipo de caso
  int? _selectedPriorityId; // Para la prioridad
  int? _selectedAssignedTechnicianId; // Para el técnico asignado
  final TextEditingController _telefonoContactoController =
      TextEditingController();
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

  void _clearForm() {
    // Reset the state of the form fields
    _formKey.currentState?.reset();

    setState(() {
      // Clear text controllers and reset all selected values
      _clientController.clear();
      _autoCompleteKey = UniqueKey(); // Reset the Autocomplete key
      _titleController.clear();
      _descriptionController.clear();
      _selectedClientId = null;
      _selectedCaseTypeId = null;
      _selectedPriorityId = null;
      _selectedAssignedTechnicianId = null;
      _selectedTentativeDate = null;
    });

    // Optionally, show a confirmation message to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Formulario limpiado.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveCase() async {
    // Valida que el formulario esté completo
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true; // Inicia el estado de carga
    });

    // Validación informativa: técnico con ticket activo en el rango de 1 hora desde la fecha/hora tentativa
    final ticketsProvider = context.read<TicketProvider>();
    final List<Ticket> tickets = ticketsProvider.tickets;
    final int? tecnicoId = _selectedAssignedTechnicianId;
    final DateTime? fechaTentativa = _selectedTentativeDate;
    // Solo tickets activos (estado 1 o 2)
    final conflictTickets = tickets.where((t) {
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
      // Ejemplo: if (t.fechaTentativaInicio < fechaTentativaFinal && t.fechaTentativaFinalizacion > fechaTentativaInicio) {...}
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
      descripcion: _descriptionController.text,
      idCliente: _selectedClientId!,
      idPersonalCreador: creatorId,
      idPersonalAsignado: _selectedAssignedTechnicianId!,
      idTipocaso: _selectedCaseTypeId!,
      idEstado: 1, // Estado "Pendiente"
      idPrioridad: _selectedPriorityId!,
      telefonoContacto: _telefonoContactoController.text.isNotEmpty
          ? _telefonoContactoController.text
          : null,
      ultimaModificacion: DateTime.now(),
      fechaTentativaInicio: _selectedTentativeDate,
      // Los campos opcionales que no tenemos se omiten
    );
    final ticketData = newTicket.toJson();

    try {
      await context.read<ApiService>().createTicket(ticketData);

      // Recargar los tickets para actualizar la lista en tiempo real
      final user = context.read<UserProvider>().user;
      await context.read<TicketProvider>().fetchTickets(user);

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
        _descriptionController.clear();
        _clientController.clear();
        _telefonoContactoController.clear();
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
      context.read<TiposCasoProvider>().fetchTiposCaso();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        autovalidateMode: AutovalidateMode.onUnfocus,
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Usamos un Consumer para escuchar los cambios en ClientProvider

            // --- Campo para Cliente (con búsqueda) ---
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

                return FormField<String>(
                  validator: (value) {
                    if (_selectedClientId == null) {
                      return 'Por favor, seleccione un cliente de la lista';
                    }
                    return null;
                  },
                  builder: (FormFieldState<String> state) {
                    return Autocomplete<Cliente>(
                      key:
                          _autoCompleteKey, // Use the unique key for the Autocomplete widget
                      // This function tells Autocomplete how to display a Client object in the text field.
                      displayStringForOption: (Cliente client) =>
                          client.razonSocial ?? 'Nombre no disponible',

                      // This builds the list of suggestions as the user types.
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<Cliente>.empty();
                        }
                        return clientProvider.clients.where((Cliente client) {
                          // Filter logic: case-insensitive search.
                          return (client.razonSocial ?? '')
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },

                      // This is called when a user selects an item from the suggestion list.
                      onSelected: (Cliente selection) {
                        setState(() {
                          _selectedClientId = selection.idCliente;
                          // Notify the FormField that a valid selection has been made.
                          state.didChange(selection.razonSocial);
                        });
                      },

                      // This builds the text field where the user will type.
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmitted) {
                        // This listener handles the case where the user types something
                        // but doesn't select an option, or clears the field.
                        controller.addListener(() {
                          // If the text doesn't match a selected client, reset the ID.
                          if (_selectedClientId != null &&
                              controller.text !=
                                  clientProvider.clients
                                      .firstWhere((c) =>
                                          c.idCliente == _selectedClientId)
                                      .razonSocial) {
                            setState(() {
                              _selectedClientId = null;
                              // Clear the FormField state to re-trigger validation.
                              state.didChange(null);
                            });
                          }
                        });

                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            labelText: 'Buscar Cliente',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.search),
                            // Display the validation error message from the FormField.
                            errorText: state.errorText,
                          ),
                        );
                      },
                    ); // close Autocomplete
                  },
                ); // close FormField
              },
            ), // close Consumer

            const SizedBox(height: 16),

            // Campo para Descripción (textarea)
            TextFormField(
              controller: _descriptionController,
              minLines: 1,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                alignLabelWithHint: false,
                prefixIcon: Icon(Icons.description),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingrese una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              autovalidateMode: AutovalidateMode.onUnfocus,
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
            Consumer<TiposCasoProvider>(
              builder: (context, tiposCasoProvider, child) {
                if (tiposCasoProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (tiposCasoProvider.errorMessage != null) {
                  return Text(
                    tiposCasoProvider.errorMessage ?? '',
                    style: const TextStyle(color: Colors.red),
                  );
                }
                return DropdownButtonFormField<int>(
                  autovalidateMode: AutovalidateMode.onUnfocus,
                  value: _selectedCaseTypeId,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Caso',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: tiposCasoProvider.tiposCaso
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
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor, seleccione un tipo de caso';
                    }
                    return null;
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              autovalidateMode: AutovalidateMode.onUnfocus,
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
            Consumer2<UserListProvider, UserProvider>(
              builder: (context, userListProvider, userProvider, child) {
                if (userListProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final currentUser = userProvider.user;
                List<Usuario> availableUsers;

                // Si el usuario es tipo 1 (técnico), solo puede asignarse a sí mismo
                if (currentUser?.idTipo == 1) {
                  availableUsers = currentUser != null ? [currentUser] : [];
                  // Auto-seleccionar al usuario actual si no hay una selección previa
                  if (_selectedAssignedTechnicianId == null &&
                      currentUser != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        _selectedAssignedTechnicianId = currentUser.idPersonal;
                      });
                    });
                  }
                } else {
                  // Si es tipo 2 (administrador), mostrar todos los técnicos
                  availableUsers = userListProvider.users;
                }

                return FormField<String>(
                  validator: (value) {
                    if (_selectedAssignedTechnicianId == null) {
                      return 'Por favor, asigne un técnico';
                    }
                    return null;
                  },
                  builder: (FormFieldState<String> state) {
                    return Autocomplete<Usuario>(
                      displayStringForOption: (Usuario user) => user.nombre,
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<Usuario>.empty();
                        }
                        return availableUsers.where((Usuario user) {
                          return user.nombre
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase());
                        });
                      },
                      onSelected: (Usuario selection) {
                        setState(() {
                          _selectedAssignedTechnicianId = selection.idPersonal;
                          state.didChange(selection.nombre);
                        });
                      },
                      fieldViewBuilder:
                          (context, controller, focusNode, onSubmitted) {
                        // Solo inicializar el valor del controller si está vacío y hay una selección
                        if (controller.text.isEmpty &&
                            _selectedAssignedTechnicianId != null) {
                          final selectedUser = availableUsers.firstWhere(
                              (u) =>
                                  u.idPersonal == _selectedAssignedTechnicianId,
                              orElse: () => availableUsers.isNotEmpty
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
                          if (_selectedAssignedTechnicianId != null &&
                              controller.text !=
                                  availableUsers
                                      .firstWhere(
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
                                                      activo: false))
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

            const SizedBox(height: 16),

            // --- Campo de teléfono de contacto opcional ---
            TextFormField(
              controller: _telefonoContactoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono de contacto (opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),

            // ... inside the build method, at the end of the Column children

            const SizedBox(height: 24),

            // --- Botones de Acción ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Botón para limpiar el formulario
                OutlinedButton(
                  onPressed: _clearForm,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 52), // Ensure consistent height
                  ),
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 16),
                // Botón para guardar el caso
                SizedBox(
                  width: 200,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveCase,
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
                    label: const Text('Guardar Caso'),
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
          ],
        ),
      ),
    );
  }
}
