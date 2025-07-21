// lib/screens/case_detail/case_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:sist_tickets/screens/confirmation_signature/confirmation_signature_screen.dart';
import 'case_detail_content.dart';
import 'edit_case_screen.dart'; // NUEVO: Importamos la nueva pantalla de edición.

class CaseDetailScreen extends StatelessWidget {
  final String caseId;

  const CaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Caso'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Caso',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditCaseScreen(caseId: caseId),
                ),
              );
            },
          ),
        ],
      ),
      body: CaseDetailContent(
        caseId: caseId,
        onBack: () => Navigator.pop(context),
        onShowConfirmationSignature: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmationSignatureScreen(caseId: caseId),
            ),
          );
        },
      ),
    );
  }
}
