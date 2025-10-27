import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sist_tickets/constants.dart'; // Assuming this file exists and contains kPrimaryColor, kSuccessColor
import 'package:sist_tickets/screens/case_detail/case_documents_page.dart';
import '../../models/ticket.dart';
import '../../providers/ticket_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../providers/tipos_caso_provider.dart';
import '../../models/tipo_caso.dart';
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
  // Controla si se muestra el menú de cambio de estado
  bool _showEstadoFabMenu = false;

  // ignore: unused_element
  void _toggleEstadoFabMenu() {
    setState(() {
      _showEstadoFabMenu = !_showEstadoFabMenu;
    });
  }

  Future<void> _cambiarEstado(Ticket? ticket, int nuevoEstado) async {
    if (ticket == null) return;
    final provider = Provider.of<TicketProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _showEstadoFabMenu = false;
    });

    // Actualizar el ticket
    final updatedTicket = Ticket(
      idCaso: ticket.idCaso,
      fecha: ticket.fecha,
      titulo: ticket.titulo,
      descripcion: ticket.descripcion,
      idCliente: ticket.idCliente,
      idPersonalCreador: ticket.idPersonalCreador,
      idPersonalAsignado: ticket.idPersonalAsignado,
      idTipocaso: ticket.idTipocaso,
      idEstado: nuevoEstado,
      idPrioridad: ticket.idPrioridad,
      ultimaModificacion: DateTime.now(),
      fechaTentativaInicio: ticket.fechaTentativaInicio,
      tecnico: ticket.tecnico,
      cliente: ticket.cliente,
      intervenciones: ticket.intervenciones,
    );
    await provider.updateTicket(ticket.idCaso.toString(), updatedTicket);

    // Crear intervención automática por cambio de estado
    final now = DateTime.now();
    final usuario = userProvider.user;
    final intervencion = TicketIntervencion(
      idCaso: ticket.idCaso,
      idIntervencion: null,
      fechaVencimiento:
          now, // El modelo requiere DateTime, se usa now aunque conceptualmente es null
      fecha: now,
      idTipoIntervencion: 4, // Actualización de datos
      detalle: 'Cambio de estado a ${_nombreEstado(nuevoEstado)}',
      tiempoUtilizado: 0, // null no permitido, se usa 0
      idContacto: usuario?.idPersonal.toString() ?? '',
    );
    await provider.addIntervencion(ticket.idCaso!, intervencion);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado actualizado a ${_nombreEstado(nuevoEstado)}'),
      ),
    );
  }

  String _nombreEstado(int estado) {
    switch (estado) {
      case 1:
        return 'Pendiente';
      case 2:
        return 'En Proceso';
      case 3:
        return 'Finalizado';
      default:
        return 'Desconocido';
    }
  }

  void abrirWhatsAppWeb(String telefono, String mensaje) async {
    // Codifica el mensaje para que sea seguro en una URL
    final String textoCodificado = Uri.encodeComponent(mensaje);

    // Construye la URL final
    final Uri url = Uri.parse('https://wa.me/$telefono?text=$textoCodificado');

    // Lanza la URL
    if (!await launchUrl(url)) {
      throw Exception('No se pudo lanzar $url');
    }
  }

  // State variable to control the visibility of the FAB menu.
  bool _isFabMenuOpen = false;
  // Animation controller for the FAB icon animation.
  late AnimationController _fabAnimationController;
  Future<void> _launchMaps(String address) async {
    if (address.isEmpty) return;

    final query = Uri.encodeComponent(address);
    Uri mapUrl;

    try {
      // Check if running on web (Chrome/Firefox/Safari)
      if (kIsWeb) {
        // For web platforms, use Google Maps web URL
        mapUrl =
            Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
      } else {
        // For mobile platforms, use native URLs
        if (Platform.isIOS) {
          // iOS - try Apple Maps first, then Google Maps
          final appleUrl = Uri.parse('maps://?q=$query');
          final googleUrl = Uri.parse('comgooglemaps://?q=$query');

          if (await canLaunchUrl(appleUrl)) {
            mapUrl = appleUrl;
          } else if (await canLaunchUrl(googleUrl)) {
            mapUrl = googleUrl;
          } else {
            // Fallback to web version on iOS
            mapUrl = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=$query');
          }
        } else if (Platform.isAndroid) {
          // Android - try Google Maps native app
          final androidUrl = Uri.parse('geo:0,0?q=$query');

          if (await canLaunchUrl(androidUrl)) {
            mapUrl = androidUrl;
          } else {
            // Fallback to web version on Android
            mapUrl = Uri.parse(
                'https://www.google.com/maps/search/?api=1&query=$query');
          }
        } else {
          // Other platforms (Windows, Linux, macOS desktop)
          mapUrl = Uri.parse(
              'https://www.google.com/maps/search/?api=1&query=$query');
        }
      }

      // Launch the URL
      await launchUrl(mapUrl,
          mode: kIsWeb
              ? LaunchMode.platformDefault
              : LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir mapas: ${e.toString()}')),
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

  void _showAddIntervencionModal(BuildContext context) {
    if (_isFabMenuOpen) {
      _toggleFabMenu();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bContext) {
        // Pass the caseId to the form
        return _AddIntervencionForm(ticketId: widget.caseId);
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
                _buildDescription(value.ticket?.descripcion ?? ''),
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
          const SizedBox(height: 16),
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
          ScaleTransition(
            alignment: Alignment.bottomRight,
            scale: CurvedAnimation(
              parent: _fabAnimationController,
              curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
            ),
            child: FloatingActionButton.extended(
              heroTag: 'fab_docs',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CaseDocumentsPage(caseId: widget.caseId),
                  ),
                );
                _toggleFabMenu();
              },
              label: const Text('Documentos'),
              icon: const Icon(Icons.edit_document),
            ),
          ),
          const SizedBox(height: 16),
          Consumer<TicketProvider>(
            builder: (context, ticketProvider, child) {
              final ticket = ticketProvider.ticket;
              final telefono = ticket?.cliente?.telefono ?? '';
              return ScaleTransition(
                alignment: Alignment.bottomRight,
                scale: CurvedAnimation(
                  parent: _fabAnimationController,
                  curve: Interval(0.0, 0.6, curve: Curves.easeOutCubic),
                ),
                child: FloatingActionButton.extended(
                  heroTag: 'fab_whatsapp',
                  onPressed: () {
                    abrirWhatsAppWeb(telefono, 'HOLA JUAN CRUZ');
                  },
                  label: const Text('Enviar Mensaje'),
                  icon: const Icon(Icons.message),
                ),
              );
            },
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
        if (ticket != null)
          PopupMenuButton<int>(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(15.0), // Adjust radius as needed
            ),
            tooltip: 'Cambiar estado',
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: () {
                  if (ticket.idEstado == 3) {
                    return kSuccessColor.withOpacity(0.2);
                  } else if (ticket.idEstado == 2) {
                    return kPrimaryColor.withOpacity(0.2);
                  } else {
                    return Colors.orange.withOpacity(0.2);
                  }
                }(),
                shape: BoxShape.circle,
              ),
              child: Icon(
                () {
                  if (ticket.idEstado == 3) {
                    return Icons.check_circle;
                  } else if (ticket.idEstado == 2) {
                    return Icons.settings_suggest_rounded;
                  } else {
                    return Icons.hourglass_empty;
                  }
                }(),
                color: () {
                  if (ticket.idEstado == 3) {
                    return kSuccessColor;
                  } else if (ticket.idEstado == 2) {
                    return kPrimaryColor;
                  } else {
                    return Colors.orange;
                  }
                }(),
                size: 32,
              ),
            ),
            onSelected: (value) => _cambiarEstado(ticket, value),
            itemBuilder: (context) {
              final List<PopupMenuEntry<int>> items = [];
              if (ticket.idEstado == 1) {
                items.add(
                  PopupMenuItem(
                    value: 2,
                    child: Row(
                      children: const [
                        Icon(Icons.settings_suggest_rounded,
                            color: kPrimaryColor),
                        SizedBox(width: 8),
                        Text('En Proceso'),
                      ],
                    ),
                  ),
                );
              }
              if (ticket.idEstado == 2) {
                items.addAll([
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: const [
                        Icon(Icons.hourglass_empty, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Pendiente'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 3,
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: kSuccessColor),
                        SizedBox(width: 8),
                        Text('Completado'),
                      ],
                    ),
                  ),
                ]);
              }
              return items;
            },
          ),
      ],
    );
  }

  Widget _buildDetails(Ticket? ticket) {
    // (fecha ya no se usa)
    return Consumer<TiposCasoProvider>(
      builder: (context, tiposCasoProvider, child) {
        String tipoCasoNombre = '';
        if (ticket?.idTipocaso != null &&
            tiposCasoProvider.tiposCaso.isNotEmpty) {
          final tipo = tiposCasoProvider.tiposCaso.firstWhere(
            (t) => t.id == ticket!.idTipocaso,
            orElse: () => TipoCaso(id: 0, nombre: '', color: 0),
          );
          tipoCasoNombre = tipo.nombre;
        }
        String prioridadTexto = '';
        switch (ticket?.idPrioridad) {
          case 1:
            prioridadTexto = 'Baja';
            break;
          case 2:
            prioridadTexto = 'Media';
            break;
          case 3:
            prioridadTexto = 'Alta';
            break;
          default:
            prioridadTexto = 'Sin prioridad';
        }
        return Card(
          elevation: 2,
          child: Padding(
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
                          ? '${DateFormat('dd-MM-yyyy').format(ticket?.fecha?.toLocal() ?? DateTime.now())} - ${DateFormat.Hm().format(ticket?.fecha?.toLocal() ?? DateTime.now())} hs'
                          : 'Fecha y hora no disponible',
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                        Icons.category,
                        tipoCasoNombre.isNotEmpty
                            ? tipoCasoNombre
                            : 'Tipo de caso no disponible'),
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.priority_high, prioridadTexto),
                    const SizedBox(height: 4),
                    _buildDetailRow(
                      Icons.person_outline,
                      ticket?.tecnico ?? 'Técnico no asignado',
                    ),
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
                const SizedBox(height: 8),
                _buildDetailRow(
                    Icons.date_range_rounded,
                    ticket?.fechaTentativaInicio != null
                        ? '${DateFormat('dd-MM-yyyy HH:mm').format(ticket!.fechaTentativaInicio!.toLocal())} hs'
                        : 'Fecha tentativa no asignada'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: (ticket?.cliente?.domicilio != null)
                      ? () {
                          final address = [
                            ticket?.cliente?.domicilio,
                            ticket?.cliente?.nombreLocalidad?.toString(),
                            ticket?.cliente?.nombreProvincia?.toString()
                          ].where((s) => s != null).join(', ');
                          _launchMaps(address);
                        }
                      : null,
                  child: () {
                    final address = [
                      ticket?.cliente?.domicilio,
                      ticket?.cliente?.nombreLocalidad?.toString(),
                      ticket?.cliente?.nombreProvincia?.toString()
                    ].where((s) => s != null).join(', ');
                    return _buildDetailRow(
                      Icons.location_on,
                      address.isEmpty ? 'Domicilio no disponible' : address,
                    );
                  }(),
                ),
                /* _buildDetailRow(Icons.location_on,
                    ticket?.cliente?.domicilio ?? 'Domicilio no disponible'), */
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
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

  Widget _buildDescription(String descripcion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          descripcion,
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
              // Detalle en negrita
              Text(
                intervencion.detalle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              // División horizontal pequeña
              const Divider(
                color: Colors.grey,
                thickness: 0.7,
                height: 16,
              ),
              // Datos de la intervención en una sola línea
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Tooltip(
                    message: 'Fecha',
                    child: const Icon(Icons.calendar_today,
                        size: 18, color: Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd-MM-yyyy HH:mm')
                        .format(intervencion.fecha.toLocal()),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 18),
                  Tooltip(
                    message: 'Tipo de intervención',
                    child:
                        const Icon(Icons.build, size: 18, color: Colors.grey),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    intervencion.tipoIntervencionLabel ??
                        '${intervencion.idTipoIntervencion}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              // Mostrar tiempo utilizado solo si es mayor a 0
              if (intervencion.tiempoUtilizado > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: 'Tiempo utilizado',
                      child:
                          const Icon(Icons.timer, size: 18, color: Colors.grey),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${intervencion.tiempoUtilizado} minutos',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
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
      children: [
        const Text(
          'Trazabilidad',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...intervenciones
            .map((intervencion) => _buildIntervencion(intervencion))
            .toList(),
      ],
    );
  }
}

// ### 3. THE FORM WIDGET FOR THE MODAL ###
// This is a new StatefulWidget to manage the form's state.

class _AddIntervencionForm extends StatefulWidget {
  final String ticketId;
  const _AddIntervencionForm({required this.ticketId});

  @override
  State<_AddIntervencionForm> createState() => __AddIntervencionFormState();
}

class __AddIntervencionFormState extends State<_AddIntervencionForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _detalleController = TextEditingController();
  final _tiempoController = TextEditingController();
  final _contactoController = TextEditingController();
  final _fechaController = TextEditingController();
  final _fechaVencimientoController = TextEditingController();

  // State variables for dropdowns and date pickers
  int? _selectedTipoIntervencion;
  DateTime? _selectedFecha;
  DateTime? _selectedFechaVencimiento;

  bool _isLoading = false;

  @override
  void dispose() {
    _detalleController.dispose();
    _tiempoController.dispose();
    _contactoController.dispose();
    _fechaController.dispose();
    _fechaVencimientoController.dispose();
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
        _fechaVencimientoController.text =
            DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime);
      } else {
        _selectedFecha = selectedDateTime;
        _fechaController.text =
            DateFormat('dd/MM/yyyy HH:mm').format(selectedDateTime);
      }
    });
  }

  // Method to handle form submission
  void _submitForm() async {
    // Validar el formulario primero
    if (!(_formKey.currentState?.validate() ?? false)) {
      return; // Si hay errores de validación, no hacer nada
    }

    // Verificar que las fechas estén seleccionadas
    if (_selectedFecha == null || _selectedFechaVencimiento == null) {
      return; // Si falta alguna fecha, no continuar
    }

    // Solo si todo está validado, proceder con la carga
    setState(() {
      _isLoading = true;
    });

    // Create the new intervention object from the form data.
    final newIntervencion = TicketIntervencion(
      fechaVencimiento: _selectedFechaVencimiento!,
      fecha: _selectedFecha!,
      idTipoIntervencion: _selectedTipoIntervencion!,
      detalle: _detalleController.text,
      tiempoUtilizado: int.tryParse(_tiempoController.text) ?? 0,
      idContacto: '', // Campo oculto, siempre vacío
    );

    try {
      final ticketProvider =
          Provider.of<TicketProvider>(context, listen: false);
      final success = await ticketProvider.addIntervencion(
          int.parse(widget.ticketId), newIntervencion);
      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Intervención añadida con éxito'),
            backgroundColor: kSuccessColor,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar la intervención'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: In a real app, you would fetch these lists from your provider/API.
    // For now, we're using dummy data.
    final List<DropdownMenuItem<int>> dummyTipos = [
      const DropdownMenuItem(value: 1, child: Text('Soporte Técnico')),
      const DropdownMenuItem(value: 2, child: Text('Mantenimiento')),
      const DropdownMenuItem(value: 3, child: Text('Instalación')),
      const DropdownMenuItem(value: 4, child: Text('Actualizacion de datos')),
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
                    child: TextFormField(
                      readOnly: true,
                      onTap: () =>
                          _selectDateTime(context, isVencimiento: false),
                      decoration: const InputDecoration(
                        labelText: 'Fecha Intervención',
                        border: OutlineInputBorder(),
                      ),
                      controller: _fechaController,
                      validator: (value) =>
                          _selectedFecha == null ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      readOnly: true,
                      onTap: () =>
                          _selectDateTime(context, isVencimiento: true),
                      decoration: const InputDecoration(
                        labelText: 'Fecha Vencimiento',
                        border: OutlineInputBorder(),
                      ),
                      controller: _fechaVencimientoController,
                      validator: (value) => _selectedFechaVencimiento == null
                          ? 'Requerido'
                          : null,
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
                  if (int.tryParse(value!) == null) {
                    return 'Ingrese un número válido';
                  }
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
