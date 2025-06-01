// lib/administrator/confirmation_signature_content.dart
import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart';

class ConfirmationSignatureContent extends StatelessWidget {
  final String caseId;
  final VoidCallback onBack;

  const ConfirmationSignatureContent({
    super.key,
    required this.caseId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título y botón de retroceso en el body
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: kPrimaryColor), // Flecha de volver
                onPressed: onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Firma de Conformidad', // Título de la sección
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              // No hay botones de editar/borrar en esta vista según las imágenes
            ],
          ),
          const SizedBox(height: 16), // Espacio debajo del encabezado

          // Área de la firma (SOLO VISUALIZACIÓN)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200], // Fondo gris claro
              border: Border.all(color: kPrimaryColor, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Aquí iría la imagen de la firma REAL cargada del backend.
                // Por ahora, mantenemos un placeholder visual.
                Image.asset(
                  'assets/firma_placeholder.png', // Asegúrate de tener esta imagen en assets/
                  fit: BoxFit.contain,
                  height: 150, // Ajusta el tamaño para que se vea bien
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Fecha: 07/02/2024',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 24),

          // Información del caso/cliente y Calificación en la misma fila (como lo habíamos ajustado)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(Icons.person, 'Ortega Juan Cruz'),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.location_on, 'Av.Avellaneda 1244'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Calificación',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  Text(
                    '9/10',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón Volver CREO Q NO HACE FALTA XQ ESTA LA FLECHA DE VOLVER
//          ElevatedButton(
//            onPressed: onBack,
//            style: ElevatedButton.styleFrom(
//              backgroundColor: kPrimaryColor,
//              foregroundColor: Colors.white,
//              padding: const EdgeInsets.symmetric(vertical: 15),
//              shape: RoundedRectangleBorder(
//                borderRadius: BorderRadius.circular(10),
//              ),
//            ),
//            
//            child: const Text(
//              'Volver',
//              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//            ),
//          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.grey[800]),
        ),
      ],
    );
  }
}