// lib/administrator/case_registered_content.dart
import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart'; 

class CaseRegisteredContent extends StatelessWidget {
  final VoidCallback onGoBackToForm;
  final VoidCallback onGoToCasesTab;

  const CaseRegisteredContent({
    super.key,
    required this.onGoBackToForm,
    required this.onGoToCasesTab,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, 
        crossAxisAlignment: CrossAxisAlignment.center, 
        children: [
          const SizedBox(height: 50), 
          Icon(
            Icons.check_circle_outline,
            color: Colors.green[700],
            size: 100,
          ),
          const SizedBox(height: 20),
          const Text(
            '¡Caso Registrado con Éxito!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Tu nuevo caso ha sido creado y se está gestionando.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onGoBackToForm,
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryColor,
                side: const BorderSide(color: kPrimaryColor),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Registrar Otro Caso',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 50), 
        ],
      ),
    );
  }
}
