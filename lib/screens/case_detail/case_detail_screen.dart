// lib/screens/case_detail/case_detail_screen.dart

import 'package:flutter/material.dart';
import 'case_detail_content.dart'; // Ruta temporal, idealmente este contenido también se mueve aquí

class CaseDetailScreen extends StatelessWidget {
  final String caseId;

  const CaseDetailScreen({super.key, required this.caseId});

  @override
  Widget build(BuildContext context) {
    // CaseDetailContent ahora vive dentro de su propio Scaffold
    // para que pueda tener su propia AppBar y manejar su ciclo de vida.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Caso'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: CaseDetailContent(
        caseId: caseId,
        onBack: () =>
            Navigator.pop(context), // El botón de volver ahora usa Navigator
        onShowConfirmationSignature: () {
          // Aquí puedes navegar a la pantalla de la firma
          // Navigator.push(context, ...);
        },
      ),
    );
  }
}
