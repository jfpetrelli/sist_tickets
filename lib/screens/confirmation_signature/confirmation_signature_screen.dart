// lib/screens/case_detail/case_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:sist_tickets/screens/confirmation_signature/confirmation_signature.dart';

class ConfirmationSignatureScreen extends StatelessWidget {
  final String caseId;

  const ConfirmationSignatureScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    // CaseDetailContent ahora vive dentro de su propio Scaffold
    // para que pueda tener su propia AppBar y manejar su ciclo de vida.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firma de Conformidad'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ConfirmationSignatureContent(
        caseId: caseId,
      ),
    );
  }
}
