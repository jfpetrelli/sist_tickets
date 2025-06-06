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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Caso Registrado!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'El caso ha sido registrado exitosamente',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onGoToCasesTab,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Ver Casos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onGoBackToForm,
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryColor,
                side: BorderSide(color: kPrimaryColor),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Registrar Otro Caso',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
