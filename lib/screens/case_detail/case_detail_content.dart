import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart'; // Assuming this file exists and contains kPrimaryColor, kSuccessColor
import '../../models/ticket.dart';
import '../../providers/ticket_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
// The flutter_speed_dial package is no longer needed.
import '../../models/intervencion_ticket.dart';

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
          // The AnimatedOpacity is replaced with individual ScaleTransitions for a staggered effect.
          // The button closest to the main FAB will appear first.
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
                _buildDetailRow(Icons.location_on,
                    ticket?.cliente?.domicilio ?? 'Domicilio no disponible'),
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

    return Card(
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
