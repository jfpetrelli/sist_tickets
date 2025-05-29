// lib/administrator/cases_content.dart
import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFFE74C3C); // E74C3C

class CasesContent extends StatelessWidget {
  const CasesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( 
      padding: const EdgeInsets.all(10.0), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        
        children: [
          _buildSectionTitle('Casos pendientes'),
          const SizedBox(height: 8),
          _buildCaseCard(context, 'Distribuidora Dique', 'Instalación redes WiFi'),
          const SizedBox(height: 4),
          _buildCaseCard(context, 'Detalle caso 2', ''),
          const SizedBox(height: 4),
          _buildCaseCard(context, 'Detalle caso 3', ''),
          const SizedBox(height: 12),

          _buildSectionTitle('Casos Completados'),
          const SizedBox(height: 8),
          _buildCaseCard(context, 'Obring', 'Instalación redes WiFi'),
          const SizedBox(height: 4),
          _buildCaseCard(context, 'Detalle caso 2', ''),
          const SizedBox(height: 4),
          _buildCaseCard(context, 'Detalle caso 3', ''),
          const SizedBox(height: 12),

          _buildNewCaseButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildCaseCard(BuildContext context, String title, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0),
        child: Row(
          children: [
            ElevatedButton(
              onPressed: () {
                print('Ver: $title');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor.withOpacity(0.9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Ver'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewCaseButton() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          print('Nuevo Caso presionado desde CasesContent!');
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: kPrimaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white, size: 20),
              SizedBox(width: 5),
              Text(
                'Nuevo Caso',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
