import 'package:flutter/material.dart';
import 'signature_pad.dart';
import 'package:sist_tickets/constants.dart';

class SignatureDialog extends StatefulWidget {
  const SignatureDialog({Key? key}) : super(key: key);

  @override
  State<SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  final GlobalKey<SignaturePadState> _signaturePadKey = GlobalKey<SignaturePadState>();
  
  Future<String?> _getSignature() async {
    final signaturePadState = _signaturePadKey.currentState;
    if (signaturePadState == null) return null;
    return await signaturePadState.exportImageBytes();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Firma de Conformidad',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Por favor, firme en el área indicada',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SignaturePad(key: _signaturePadKey),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _signaturePadKey.currentState?.clear();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  child: const Text('Limpiar', style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final signature = await _getSignature();
                    if (signature != null && signature.isNotEmpty) {
                      Navigator.of(context).pop(signature);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, realice una firma'),
                          backgroundColor: kErrorColor,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                  ),
                  child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

