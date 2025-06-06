import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart'; // Asumiendo que 'constants.dart' define kPrimaryColor y kSuccessColor

class ReportsContent extends StatelessWidget {
  const ReportsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tareas',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Informacion Estadística',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildTasksStatsCard(),
          const SizedBox(height: 30),
          Text(
            'Ranking Técnicos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          _buildTechnicianRanking(),
        ],
      ),
    );
  }

  Widget _buildTasksStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: 0.75, // 75% completado
                        strokeWidth: 12,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '75%',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'COMPLETADOS',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem('Completados', '23 casos', kPrimaryColor),
                      const SizedBox(height: 10),
                      _buildStatItem('Pendientes', '5 casos', Colors.grey),
                      const SizedBox(height: 10),
                      _buildStatItem('En progreso', '5 casos', Colors.lightBlue),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Manejar la acción de exportar
                  print('Exportar Tareas');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350), // Un color rojizo para exportar
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Exportar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 2,
          color: color,
          margin: const EdgeInsets.only(right: 8),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianRanking() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTechnicianRankItem('Ortega Coldorf, Juan Cruz', '@Jortega', '8.4', true),
            const Divider(),
            _buildTechnicianRankItem('Schiavoni, Franco Bernabé', '@Fschiavoni', '8.1', false),
            const Divider(),
            _buildTechnicianRankItem('Petrelli, Juan Franco', '@JFpistelli', '7.3', true),
            const Divider(),
            _buildTechnicianRankItem('Massetini, Santiago', '@Smasetini', '6.9', true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Manejar la acción de exportar
                  print('Exportar Ranking');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF5350), // Un color rojizo para exportar
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Exportar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianRankItem(String name, String handle, String score, bool isUp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: kPrimaryColor.withOpacity(0.1),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                handle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            score,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isUp ? kSuccessColor : Colors.red,
            ),
          ),
          Icon(
            isUp ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: isUp ? kSuccessColor : Colors.red,
          ),
        ],
      ),
    );
  }
}