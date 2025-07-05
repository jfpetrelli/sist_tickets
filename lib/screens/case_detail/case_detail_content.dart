import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart'; // Assuming this file exists and contains kPrimaryColor, kSuccessColor
import '../../models/ticket.dart';
import '../../providers/ticket_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sist_tickets/widgets/button_widget_standard.dart';

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

class _CaseDetailContentState extends State<CaseDetailContent> {
  // You can now introduce state variables here.
  // For example:
  // bool _isLoading = true;
  // Map<String, dynamic>? _caseData;

  @override
  void initState() {
    super.initState();
    // This schedules a callback to be executed after the first frame is rendered.
    // It safely calls the provider to fetch the initial list of tickets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false)
          .getTicketById(widget.caseId);
    });
  }

  // void _fetchCaseDetails() {
  //   // Example: logic to fetch data using widget.caseId
  //   setState(() {
  //     _isLoading = false;
  //     _caseData = { ... }; // Your fetched data
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // If you were loading data, you could show a spinner:
    // if (_isLoading) {
    //   return const Center(child: CircularProgressIndicator());
    // }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Consumer<TicketProvider>(
        builder: (context, value, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(value.ticket),
              const SizedBox(height: 24),
              _buildDetails(value.ticket),
              const SizedBox(height: 24),
              _buildDocuments(value.ticket?.idCaso.toString() ?? ''),
              const SizedBox(height: 24),
              _buildDescription(),
            ],
          );
        },
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
          child: Icon(
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
            size: 24,
          ),
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
      // Añadimos clipBehavior para asegurar que el contenido respete los bordes redondeados.
      clipBehavior: Clip.antiAlias,
      child: Stack(
        // 1. Usamos un Stack para poder apilar widgets.
        children: [
          // Este es el contenido principal de la tarjeta.
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
                // 3. Añadimos espacio extra para que el contenido no se solape con la caja flotante.
                // Puedes ajustar este valor según el tamaño de la caja.
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

          // 2. Esta es la caja flotante del técnico.
          Positioned(
            top: 16, // Distancia desde arriba.
            right: 16, // Distancia desde la derecha.
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    // Sombra opcional para darle más profundidad.
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
                    ticket?.idPersonalAsignado.toString() ??
                        'Técnico no asignado',
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

  Widget _buildDocuments(String ticketId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            StandardIconButton(
              text: 'Documentos',
              icon: Icons.edit_document,
              onPressed: () {
                // Logic for downloading documents can be implemented here.
              },
            ),
            StandardIconButton(
              text: 'Ver firma',
              icon: Icons.verified,
              onPressed: widget.onShowConfirmationSignature,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
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
}
