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

class NewCaseTab extends StatefulWidget {
  const NewCaseTab({super.key});

  @override
  State<NewCaseTab> createState() => _NewCaseTabState();
}

class _NewCaseTabState extends State<NewCaseTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _clientController = TextEditingController();
  var _autoCompleteKey = UniqueKey(); // Key for the Autocomplete widget

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

  void _clearForm() {
    // Reset the state of the form fields
    _formKey.currentState?.reset();

    setState(() {
      // Clear text controllers and reset all selected values
      _clientController.clear();
      _autoCompleteKey = UniqueKey(); // Reset the Autocomplete key
      _titleController.clear();
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
        _clientController.clear();
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
            const Text(
              'Nuevo Caso',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Usamos un Consumer para escuchar los cambios en ClientProvider
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

                // We wrap Autocomplete in a FormField to integrate with the form's validation.
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
                    );
                  },
                );
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
            Consumer<UserListProvider>(
              builder: (context, userListProvider, child) {
                if (userListProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return DropdownButtonFormField<int>(
                  autovalidateMode: AutovalidateMode.onUnfocus,
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

            // ... inside the build method, at the end of the Column children

            const SizedBox(height: 24),

            // --- Botones de Acción ---
            Row(
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
                // Botón para guardar el caso (se expande para llenar el espacio)
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveCase,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar Caso'),
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
