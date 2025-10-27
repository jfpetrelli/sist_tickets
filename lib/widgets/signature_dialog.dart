import 'package:flutter/material.dart';
import 'signature_pad.dart';
import 'package:sist_tickets/constants.dart';

class SignatureDialog extends StatefulWidget {
  const SignatureDialog({Key? key}) : super(key: key);

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final GlobalKey<SignaturePadState> _signaturePadKey =
      GlobalKey<SignaturePadState>();

  Future<String?> _getSignature() async {
    final signaturePadState = _signaturePadKey.currentState;
    if (signaturePadState == null) return null;
    return await signaturePadState.exportImageBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título del diálogo
            const Text(
              'Firma de Conformidad',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Instrucción clara
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Por favor, firme en el área indicada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),

            // Área de firma con borde y estilo delimitado
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SignaturePad(key: _signaturePadKey),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botones de acción con jerarquía clara
            Row(
              children: [
                // Botón Limpiar - Secundario (OutlinedButton)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _signaturePadKey.currentState?.clear();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text(
                      'Limpiar',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Botón Confirmar - Principal (ElevatedButton)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final signature = await _getSignature();
                      if (signature != null && signature.isNotEmpty) {
                        Navigator.of(context).pop(signature);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Por favor, realice una firma antes de confirmar'),
                            backgroundColor: kErrorColor,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text(
                      'Confirmar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Botón Cancelar como TextButton
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
