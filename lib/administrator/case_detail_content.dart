// lib/administrator/case_detail_content.dart
import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart';

class CaseDetailContent extends StatelessWidget {
  final String caseId;
  final VoidCallback onBackToList; 

  const CaseDetailContent({
    super.key,
    required this.caseId,
    required this.onBackToList,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: kPrimaryColor),
                onPressed: onBackToList,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Detalle del Caso',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.edit, color: kPrimaryColor),
                onPressed: () {
                  print('Editar caso $caseId (desde el body)');
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: kPrimaryColor),
                onPressed: () {
                  print('Eliminar caso $caseId (desde el body)');

                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Distribuidora DIQUE (ID: $caseId)',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Instalación redes WIFI',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.download,
                                  size: 16,
                                  color: Colors.green[700],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.settings,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),

                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '07/02/2024',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '14:00 PM - 16:00 PM',
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.notifications_active, size: 18, color: Colors.grey[600]),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),

                  Text(
                    'Detalles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.build, 'Instalación'),
                  _buildDetailRow(Icons.person, 'Franco Schiavoni'),
                  _buildDetailRow(Icons.location_on, 'Av. Arellaneda 2500'),
                  _buildDetailRow(Icons.check_box, 'Pendiente', color: kPrimaryColor),
                  const Divider(height: 30, thickness: 1),

                  Text(
                    'Documentos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('Descargar documentos para caso $caseId');
                      },
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text(
                        'Descargar documentos',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('Ver firma de conformidad para caso $caseId');
                      },
                      icon: const Icon(Icons.description, color: Colors.grey),
                      label: const Text(
                        'Ver firma de conformidad',
                        style: TextStyle(color: Colors.grey),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 30, thickness: 1),
                  Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              color: color ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}