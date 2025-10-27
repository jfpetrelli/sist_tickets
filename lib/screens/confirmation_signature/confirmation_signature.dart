import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/adjunto_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../models/adjunto.dart';
import '../../widgets/signature_dialog.dart';
import '../../constants.dart';
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (_signatureAttachment == null)
                      Column(
                        children: [
                          const Text(
                            'No hay firma de conformidad registrada',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => _showSignatureDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 30),
                            ),
                            child: const Text(
                              'Firmar Ahora',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          const Text(
                            'Firma de Conformidad',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            height: 200,
                            margin: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: _signatureAttachment
                                          ?.filepath.isNotEmpty ==
                                      true
                                  ? Image.network(
                                      'http://localhost:8000/adjuntos/${_signatureAttachment!.idAdjunto}',
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child:
                                              Text('Error al cargar la firma'),
                                        );
                                      },
                                    )
                                  : const Center(child: Text('No hay imagen')),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Fecha: ${_formatDate(_signatureAttachment!.fecha)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () => _showSignatureDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 20),
                            ),
                            child: const Text(
                              'Actualizar Firma',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Volver',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
