// lib/administrator/cases_content.dart
import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart';

class CasesContent extends StatelessWidget {
  final ValueChanged<String> onShowCaseDetail;

  const CasesContent({
    super.key,
    required this.onShowCaseDetail,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Casos Pendientes',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildCasesList([
            _CaseItem(
              title: 'Distribuidora Dique',
              subtitle: 'Instalación redes WIFI',
              onTap: () => onShowCaseDetail('1'),
            ),
            _CaseItem(
              title: 'Detalle caso 2',
              subtitle: 'Descripción breve',
              onTap: () => onShowCaseDetail('2'),
            ),
            _CaseItem(
              title: 'Detalle caso 3',
              subtitle: 'Descripción breve',
              onTap: () => onShowCaseDetail('3'),
            ),
          ]),
          const SizedBox(height: 16),
          Text(
            'Casos Completados',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildCasesList([
            _CaseItem(
              title: 'Obring',
              subtitle: 'Instalación redes WIFI',
              isCompleted: true,
              onTap: () => onShowCaseDetail('4'),
            ),
            _CaseItem(
              title: 'Detalle caso 2',
              subtitle: 'Descripción breve',
              isCompleted: true,
              onTap: () => onShowCaseDetail('5'),
            ),
            _CaseItem(
              title: 'Detalle caso 3',
              subtitle: 'Descripción breve',
              isCompleted: true,
              onTap: () => onShowCaseDetail('6'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildCasesList(List<_CaseItem> cases) {
    return Column(
      children: cases.map((caseItem) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 18.0),
          child: Card(
            elevation: 1,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              leading: ElevatedButton(
                onPressed: caseItem.onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 0,
                  ),
                  minimumSize: const Size(40, 30),
                ),
                child: const Text(
                  'Ver',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                caseItem.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                caseItem.subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CaseItem {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onTap;

  const _CaseItem({
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    required this.onTap,
  });
}