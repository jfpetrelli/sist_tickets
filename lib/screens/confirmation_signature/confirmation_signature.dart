import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/adjunto_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../models/adjunto.dart';
import '../../widgets/signature_dialog.dart';
import '../../constants.dart';
import '../../api/api_config.dart';
import 'dart:convert';

class ConfirmationSignatureContent extends StatefulWidget {
  final String caseId;

  const ConfirmationSignatureContent({
    super.key,
    required this.caseId,
  });

  @override
  State<ConfirmationSignatureContent> createState() =>
      _ConfirmationSignatureContentState();
}

class _ConfirmationSignatureContentState
    extends State<ConfirmationSignatureContent> {
  late Future<void> _loadSignature =
      Future.value(); // Inicializado con un Future completado
  Adjunto? _signatureAttachment;

  @override
  void initState() {
    super.initState();
    // Usar addPostFrameCallback para evitar llamar al provider durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSignature = _loadSignatureFromAttachments();
    });
  }

  Future<void> _loadSignatureFromAttachments() async {
    try {
      final adjuntoProvider =
          Provider.of<AdjuntoProvider>(context, listen: false);
      await adjuntoProvider.fetchAdjuntos(widget.caseId);

      // Buscar TODAS las firmas de conformidad y obtener la última (más reciente)
      final firmas = adjuntoProvider.adjuntos
          .where((adjunto) => adjunto.filename.startsWith('firma_conformidad_'))
          .toList();

      if (firmas.isNotEmpty) {
        // Ordenar por fecha descendente para obtener la más reciente
        firmas.sort((a, b) => b.fecha.compareTo(a.fecha));
        final firmaMasReciente = firmas.first;

        if (mounted) {
          setState(() {
            _signatureAttachment = firmaMasReciente;
          });
        }
      } else {
        // No hay firmas
        if (mounted) {
          setState(() {
            _signatureAttachment = null;
          });
        }
      }
    } catch (e) {
      print('Error al cargar adjuntos: $e');
      if (mounted) {
        setState(() {
          _signatureAttachment = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadSignature,
      builder: (context, snapshot) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_signatureAttachment == null)
                // Pantalla "Sin Firma" - Firmar Ahora es principal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.draw,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No hay firma de conformidad registrada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Firma la conformidad del servicio realizado',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Botón principal - Firmar Ahora
                    Consumer<TicketProvider>(
                      builder: (context, ticketProvider, child) {
                        final ticket = ticketProvider.ticket;
                        final isEnabled = ticket?.idEstado == 3 && !kIsWeb;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isEnabled ? () => _showSignatureDialog(context) : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              disabledBackgroundColor: Colors.grey[300],
                            ),
                            icon: const Icon(Icons.edit, size: 20),
                            label: const Text(
                              'Firmar Ahora',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Botón secundario - Volver
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: kPrimaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Volver',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Pantalla "Firma Existente" - Volver es principal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card con la firma
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _signatureAttachment
                                            ?.filepath.isNotEmpty ==
                                        true
                                    ? Image.network(
                                        '${ApiConfig.baseUrl}/adjuntos/${_signatureAttachment!.idAdjunto}',
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.error_outline,
                                                    size: 48,
                                                    color: Colors.grey[400]),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'Error al cargar la firma',
                                                  style: TextStyle(
                                                      color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Text(
                                          'No hay imagen',
                                          style: TextStyle(
                                              color: Colors.grey[600]),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green[600],
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Firma registrada',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  _formatDate(_signatureAttachment!.fecha),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Botón principal - Volver
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Volver',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Botón secundario - Actualizar Firma
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: !kIsWeb ? () => _showSignatureDialog(context) : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: kPrimaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.refresh, size: 20),
                        label: const Text(
                          'Actualizar Firma',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSignatureDialog(BuildContext context) async {
    final signature = await showDialog<String>(
      context: context,
      builder: (context) => const SignatureDialog(),
    );

    if (signature == null || signature.isEmpty) {
      print('Usuario canceló la firma o la firma está vacía');
      return;
    }

    print('Firma obtenida, iniciando guardado...');

    // Guardar la firma
    try {
      final adjuntoProvider =
          Provider.of<AdjuntoProvider>(context, listen: false);
      final ticketProvider =
          Provider.of<TicketProvider>(context, listen: false);
      final ticket = ticketProvider.ticket;

      print('Ticket obtenido: ${ticket?.idCaso}');

      if (ticket == null) {
        print('ERROR: No se pudo obtener el ticket');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo obtener el ticket'),
              backgroundColor: kErrorColor,
            ),
          );
        }
        return;
      }

      final signatureBytes = base64Decode(signature);
      final signatureFileName =
          'firma_conformidad_${ticket.idCaso}_${DateTime.now().millisecondsSinceEpoch}.png';

      print('Preparando para subir firma:');
      print('- Ticket ID: ${ticket.idCaso}');
      print('- Nombre de archivo: $signatureFileName');
      print('- Tamaño: ${signatureBytes.length} bytes');

      await adjuntoProvider.uploadAdjuntoFromBytes(
        ticket.idCaso.toString(),
        signatureFileName,
        signatureBytes,
      );

      print('✅ Firma subida correctamente, recargando adjuntos...');

      // Recargar adjuntos para ver la nueva firma
      await _loadSignatureFromAttachments();

      // Forzar actualización del FutureBuilder
      if (mounted) {
        setState(() {});
      }

      print('✅ Adjuntos recargados');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firma guardada correctamente'),
            backgroundColor: kSuccessColor,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error al guardar la firma: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la firma: $e'),
            backgroundColor: kErrorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}
