import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart'; // Assuming this file exists and contains kPrimaryColor, kSuccessColor
import '../../models/ticket.dart';
import '../../providers/ticket_provider.dart';
import 'package:provider/provider.dart';

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
                ticket?.idCliente.toString() ?? 'Cliente no disponible',
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
            color: kSuccessColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: kSuccessColor,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails(Ticket? ticket) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    ticket?.fecha?.toLocal().toString().split(' ')[0] ??
                        'Fecha no disponible'),
                const SizedBox(height: 4),
                _buildDetailRow(Icons.access_time, '8:00 AM - 10:00 AM'),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
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
            const SizedBox(height: 16),
            _buildDetailRow(Icons.location_on, 'Av.Avellaneda 1244'),
            const SizedBox(height: 16),
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
        const Text(
          'Documentos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            // Logic for downloading documents can be implemented here.
          },
          icon: const Icon(Icons.download),
          label: const Text('Descargar documentos'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: widget.onShowConfirmationSignature,
          //widget.onShowConfirmationSignature, // Access callback via widget
          icon: const Icon(Icons.verified),
          label: const Text('Ver firma de conformidad'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
          ),
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
