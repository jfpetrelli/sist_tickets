import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sist_tickets/constants.dart'; // Assuming this file exists and contains kPrimaryColor, kSuccessColor
import '../../models/ticket.dart';
import '../../providers/ticket_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/intervencion_ticket.dart';
import 'package:url_launcher/url_launcher.dart';

class CaseDetailContent extends StatefulWidget {
  final String caseId;
  final VoidCallback onBack;
  final VoidCallback onShowConfirmationSignature;

  const CaseDetailContent({
    super.key,
    required this.caseId,
    required this.onBack,
    required this.onShowConfirmationSignature,
  });

  @override
  State<CaseDetailContent> createState() => _CaseDetailContentState();
}

// Add SingleTickerProviderStateMixin to handle the animation controller.
class _CaseDetailContentState extends State<CaseDetailContent>
    with SingleTickerProviderStateMixin {
  // State variable to control the visibility of the FAB menu.
  bool _isFabMenuOpen = false;
  // Animation controller for the FAB icon animation.
  late AnimationController _fabAnimationController;
  Future<void> _launchMaps(String address) async {
    if (address.isEmpty) return;

    final query = Uri.encodeComponent(address);
    Uri? appleUrl;
    Uri? googleUrl;

    // Check the platform and create the appropriate native URL
    if (Platform.isIOS) {
      // iOS
      appleUrl = Uri.parse('maps://?q=$query');
      googleUrl = Uri.parse('comgooglemaps://?q=$query');
    } else if (Platform.isAndroid) {
      // Android
      googleUrl = Uri.parse('geo:0,0?q=$query');
    }

    try {
      // Try to launch the native app URL
      if (googleUrl != null && await canLaunchUrl(googleUrl)) {
        // This will launch Google Maps on either platform if installed
        await launchUrl(googleUrl);
      } else if (appleUrl != null && await canLaunchUrl(appleUrl)) {
        // This will launch Apple Maps on iOS as a fallback
        await launchUrl(appleUrl);
      } else {
        throw 'No se pudo abrir una aplicación de mapas.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller.
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 400), // Slightly longer duration for a smoother effect
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false)
          .getTicketById(widget.caseId);
    });
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is removed.
    _fabAnimationController.dispose();
    super.dispose();
  }

  // Method to toggle the FAB menu's visibility and run the animation.
  void _toggleFabMenu() {
    setState(() {
      _isFabMenuOpen = !_isFabMenuOpen;
      if (_isFabMenuOpen) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    });
  }

// ### 1. FUNCTION TO SHOW THE MODAL ###
  // This function is called by the new FAB. It displays a modal bottom sheet
  // containing the form for the new intervention.
  void _showAddIntervencionModal(BuildContext context) {
    // Close the FAB menu when opening the modal
    if (_isFabMenuOpen) {
      _toggleFabMenu();
    }

    showModalBottomSheet(
      context: context,
      // isScrollControlled allows the modal to take up more screen space,
      // which is crucial for forms, especially when the keyboard appears.
      isScrollControlled: true,
      // Using a rounded shape for the top corners of the modal.
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) {
        // We pass the ticketId to the form so it knows where to associate the new intervention.
        return _AddIntervencionForm();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<TicketProvider>(
          builder: (context, value, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(value.ticket),
                const SizedBox(height: 24),
                _buildDescription(),
                const SizedBox(height: 24),
                _buildDetails(value.ticket),
                const SizedBox(height: 24),
                _buildIntervencionesList(value.ticket?.intervenciones ?? []),
              ],
            );
          },
        ),
      ),
      // Replace the SpeedDial with a custom Column of FloatingActionButtons.
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ScaleTransition(
            alignment: Alignment.bottomRight,
            scale: CurvedAnimation(
              parent: _fabAnimationController,
              // The interval is adjusted to appear after the other buttons.
              curve: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
            ),
            child: FloatingActionButton.extended(
              heroTag: 'fab_add_intervention',
              onPressed: () {
                // Call the function to show the modal, passing the current ticket.
                _showAddIntervencionModal(context);
              },
              label: const Text('Añadir Intervención'),
              icon: const Icon(Icons.post_add),
            ),
          ),
          ScaleTransition(
            alignment: Alignment.bottomRight,
            scale: CurvedAnimation(
              parent: _fabAnimationController,
              // This interval makes the button animate in the first 60% of the duration.
              curve: Interval(0.2, 0.8, curve: Curves.easeOutCubic),
            ),
            child: FloatingActionButton.extended(
              heroTag: 'fab_signature',
              onPressed: () {
                widget.onShowConfirmationSignature();
                _toggleFabMenu();
              },
              label: const Text('Ver firma'),
              icon: const Icon(Icons.verified),
            ),
          ),
          const SizedBox(height: 16),
          // This button will appear slightly after the first one.
          ScaleTransition(
            alignment: Alignment.bottomRight,
            scale: CurvedAnimation(
              parent: _fabAnimationController,
              // This interval makes the button animate between 20% and 80% of the duration.
              curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
            ),
            child: FloatingActionButton.extended(
              heroTag: 'fab_docs',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Acción de documentos presionada.')),
                );
                _toggleFabMenu();
              },
              label: const Text('Documentos'),
              icon: const Icon(Icons.edit_document),
            ),
          ),
          const SizedBox(height: 16),
          // This is the main FAB that toggles the menu.
          FloatingActionButton(
            shape: const CircleBorder(),
            backgroundColor: kPrimaryColor,
            heroTag: 'fab_main_menu',
            onPressed: _toggleFabMenu,
            // Use AnimatedIcon for a smooth transition between menu and close icons.
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              color: Colors.white,
              progress: _fabAnimationController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Ticket? ticket) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket?.cliente?.razonSocial ?? 'Cliente no disponible',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticket?.titulo ?? 'Título no disponible',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: () {
              if (ticket?.idEstado == 3) {
                return kSuccessColor.withOpacity(0.2);
              } else if (ticket?.idEstado == 2) {
                return kPrimaryColor.withOpacity(0.2);
              } else {
                return Colors.orange.withOpacity(0.2);
              }
            }(),
            shape: BoxShape.circle,
          ),
          child: IconButton(
              onPressed: VoidCallbackAction.new,
              icon: Icon(
                () {
                  if (ticket?.idEstado == 3) {
                    return Icons.check_circle;
                  } else if (ticket?.idEstado == 2) {
                    return Icons.settings_suggest_rounded;
                  } else {
                    return Icons.hourglass_empty;
                  }
                }(),
                color: () {
                  if (ticket?.idEstado == 3) {
                    return kSuccessColor;
                  } else if (ticket?.idEstado == 2) {
                    return kPrimaryColor;
                  } else {
                    return Colors.orange;
                  }
                }(),
              )),
        ),
      ],
    );
  }

  Widget _buildDetails(Ticket? ticket) {
    DateTime fecha = ticket?.fecha?.toLocal() ?? DateTime.now();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detalles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        Icons.calendar_today,
                        ticket?.fecha != null
                            ? DateFormat('dd-MM-yyyy')
                                .format(ticket!.fecha!.toLocal())
                            : 'Fecha no disponible'),
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.access_time,
                        '${DateFormat.Hm().format(fecha)} hs'),
                  ],
                ),
                const SizedBox(height: 4),
                const Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),
                const Text(
                  'Visita técnica',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                    Icons.date_range_rounded,
                    ticket?.fechaTentativaInicio != null
                        ? '${DateFormat('dd-MM-yyyy HH:mm').format(ticket!.fechaTentativaInicio!.toLocal())} hs'
                        : 'Fecha tentativa no asignada'),
                InkWell(
                  // Disable the tap if the address is null or empty
                  onTap: (ticket?.cliente?.domicilio != null)
                      ? () => _launchMaps(ticket?.cliente?.domicilio ?? '')
                      : null,
                  child: _buildDetailRow(Icons.location_on,
                      ticket?.cliente?.domicilio ?? 'Domicilio no disponible'),
                ),
                /* _buildDetailRow(Icons.location_on,
                    ticket?.cliente?.domicilio ?? 'Domicilio no disponible'), */
                const SizedBox(height: 16),
                const Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calificación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: kSuccessColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '9/10',
                        style: TextStyle(
                          color: kSuccessColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    )
                  ]),
              child: Column(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Técnico',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    ticket?.tecnico ?? 'Técnico no asignado',
                    softWrap: true,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIntervencion(TicketIntervencion? intervencion) {
    if (intervencion == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                intervencion.detalle,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                'Fecha: ${DateFormat('dd-MM-yyyy HH:mm').format(intervencion.fecha.toLocal())}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntervencionesList(List<TicketIntervencion> intervenciones) {
    if (intervenciones.isEmpty) {
      return const Text('No hay intervenciones registradas.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: intervenciones
          .map((intervencion) => _buildIntervencion(intervencion))
          .toList(),
    );
  }
}

// ### 3. THE FORM WIDGET FOR THE MODAL ###
// This is a new StatefulWidget to manage the form's state.
class _AddIntervencionForm extends StatefulWidget {
  // We need the ticketId to associate the new intervention.
  //final int ticketId;

  const _AddIntervencionForm(/* {required this.ticketId} */);

  @override
  State<_AddIntervencionForm> createState() => __AddIntervencionFormState();
}

class __AddIntervencionFormState extends State<_AddIntervencionForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _detalleController = TextEditingController();
  final _tiempoController = TextEditingController();

  // State variables for dropdowns and date pickers
  int? _selectedTipoIntervencion;
  int? _selectedContacto;
  DateTime? _selectedFecha;
  DateTime? _selectedFechaVencimiento;

  bool _isLoading = false;

  @override
  void dispose() {
    _detalleController.dispose();
    _tiempoController.dispose();
    super.dispose();
  }

  // Helper method to show a date and time picker.
  Future<void> _selectDateTime(BuildContext context,
      {required bool isVencimiento}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate == null) return;

    if (!mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );
    if (pickedTime == null) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isVencimiento) {
        _selectedFechaVencimiento = selectedDateTime;
      } else {
        _selectedFecha = selectedDateTime;
      }
    });
  }

  // Method to handle form submission
  void _submitForm() async {
    // First, validate the form.
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // Create the new intervention object from the form data.
      final newIntervencion = TicketIntervencion(
        //idCaso: widget.ticketId,
        fechaVencimiento: _selectedFechaVencimiento!,
        fecha: _selectedFecha!,
        idTipoIntervencion: _selectedTipoIntervencion!,
        detalle: _detalleController.text,
        // Ensure tiempoUtilizado is parsed correctly.
        tiempoUtilizado: int.tryParse(_tiempoController.text) ?? 0,
        idContacto: _selectedContacto!,
      );

      try {
        // ### 4. CALL THE PROVIDER TO SAVE THE DATA ###
        // You'll need to implement the `addIntervencion` method in your TicketProvider.
        /* await Provider.of<TicketProvider>(context, listen: false)
            .addIntervencion(newIntervencion); */

        if (mounted) {
          // Close the modal on success.
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Intervención añadida con éxito'),
              backgroundColor: kSuccessColor,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $error'),
              backgroundColor: Colors.red,
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
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: In a real app, you would fetch these lists from your provider/API.
    // For now, we're using dummy data.
    final List<DropdownMenuItem<int>> dummyTipos = [
      const DropdownMenuItem(value: 1, child: Text('Soporte Técnico')),
      const DropdownMenuItem(value: 2, child: Text('Mantenimiento')),
      const DropdownMenuItem(value: 3, child: Text('Instalación')),
    ];
    final List<DropdownMenuItem<int>> dummyContactos = [
      const DropdownMenuItem(value: 101, child: Text('Juan Pérez')),
      const DropdownMenuItem(value: 102, child: Text('Maria Gómez')),
    ];

    // This Padding ensures the content is not hidden by the keyboard.
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
              Text(
                'Añadir Nueva Intervención',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),

              // --- Form Fields ---

              // Detail Text Field
              TextFormField(
                controller: _detalleController,
                decoration: const InputDecoration(
                  labelText: 'Detalle de la intervención',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) => (value?.isEmpty ?? true)
                    ? 'El detalle es obligatorio'
                    : null,
              ),
              const SizedBox(height: 16),

              // Date Fields
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          _selectDateTime(context, isVencimiento: false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha Intervención',
                          border: const OutlineInputBorder(),
                          errorText:
                              (_formKey.currentState?.validate() ?? false) &&
                                      _selectedFecha == null
                                  ? 'Requerido'
                                  : null,
                        ),
                        child: Text(
                          _selectedFecha != null
                              ? DateFormat('dd/MM/yyyy HH:mm')
                                  .format(_selectedFecha!)
                              : 'Seleccionar...',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () =>
                          _selectDateTime(context, isVencimiento: true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Fecha Vencimiento',
                          border: const OutlineInputBorder(),
                          errorText:
                              (_formKey.currentState?.validate() ?? false) &&
                                      _selectedFechaVencimiento == null
                                  ? 'Requerido'
                                  : null,
                        ),
                        child: Text(
                          _selectedFechaVencimiento != null
                              ? DateFormat('dd/MM/yyyy HH:mm')
                                  .format(_selectedFechaVencimiento!)
                              : 'Seleccionar...',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dropdowns
              DropdownButtonFormField<int>(
                value: _selectedTipoIntervencion,
                items: dummyTipos,
                onChanged: (value) =>
                    setState(() => _selectedTipoIntervencion = value),
                decoration: const InputDecoration(
                  labelText: 'Tipo de Intervención',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Seleccione un tipo' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedContacto,
                items: dummyContactos,
                onChanged: (value) => setState(() => _selectedContacto = value),
                decoration: const InputDecoration(
                  labelText: 'Contacto',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Seleccione un contacto' : null,
              ),
              const SizedBox(height: 16),

              // Time Used
              TextFormField(
                controller: _tiempoController,
                decoration: const InputDecoration(
                  labelText: 'Tiempo Utilizado (minutos)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'El tiempo es obligatorio';
                  if (int.tryParse(value!) == null)
                    return 'Ingrese un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text('Guardar Intervención',
                          style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
