import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sist_tickets/api/api_service.dart';
import 'package:sist_tickets/constants.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:sist_tickets/utils/pdf_downloader.dart';

class ReportsContent extends StatefulWidget {
  const ReportsContent({super.key});

  @override
  State<ReportsContent> createState() => _ReportsContentState();
}

class _ReportsContentState extends State<ReportsContent> {
  Map<String, dynamic>? _ticketStats;

  @override
  void initState() {
    super.initState();
    _fetchTicketStats();
  }

  Future<void> _fetchTicketStats() async {
    try {
      final stats = await ApiService().getTicketStats();
      setState(() {
        _ticketStats = stats;
      });
    } catch (e) {
      debugPrint('Error fetching ticket stats: $e');
    }
  }

  Future<void> _exportStatistics() async {
    if (_ticketStats == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay datos para exportar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generando reporte PDF...'),
          backgroundColor: Colors.blue,
        ),
      );

      final pdf = await _generatePDFReport();
      final fileName =
          'Reporte_Estadisticas_${DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now())}.pdf';

      if (kIsWeb) {
        // Para Flutter Web: descargar usando helper
        final pdfBytes = await pdf.save();
        downloadPdf(pdfBytes, fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reporte PDF descargado: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // Para móvil: guardar en el dispositivo
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      // Guardar el PDF
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte PDF guardado: $fileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ver ubicación',
              textColor: Colors.white,
              onPressed: () {
                debugPrint('PDF guardado en: ${file.path}');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ubicación: ${file.path}'),
                    duration: const Duration(seconds: 5),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error generando PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al generar el reporte PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<pw.Document> _generatePDFReport() async {
    final pdf = pw.Document();

    // Extraer datos
    final ticketsUltimos7Dias = _ticketStats!['tickets_ultimos_7_dias'] ?? 0;
    final ticketsResueltosUltimos7Dias =
        _ticketStats!['tickets_resueltos_ultimos_7_dias'] ?? 0;
    final tiempoPromedioResolucion =
        _ticketStats!['tiempo_promedio_resolucion']?.toDouble() ?? 0.0;

    final ticketsPorEstado =
        _ticketStats!['tickets_por_estado'] as List<dynamic>? ?? [];
    final ticketsPorTecnico =
        _ticketStats!['tickets_por_tecnico_y_estado'] as List<dynamic>? ?? [];

    // Calcular totales por estado
    int pendientes = 0, enProceso = 0, finalizados = 0, cancelados = 0;
    for (var item in ticketsPorEstado) {
      final count = item['count'] as int;
      switch (item['id_estado']) {
        case 1:
          pendientes = count;
          break;
        case 2:
          enProceso = count;
          break;
        case 3:
          finalizados = count;
          break;
        case 4:
          cancelados = count;
          break;
      }
    }

    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Reporte de Estadísticas',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    fecha,
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // KPIs Section
              pw.Text(
                'Indicadores Clave',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildPDFKPIRow('Tickets Creados (últimos 7 días)',
                        '$ticketsUltimos7Dias'),
                    pw.SizedBox(height: 8),
                    _buildPDFKPIRow('Tickets Resueltos (últimos 7 días)',
                        '$ticketsResueltosUltimos7Dias'),
                    pw.SizedBox(height: 8),
                    _buildPDFKPIRow('Tiempo Promedio de Resolución',
                        '${tiempoPromedioResolucion.toStringAsFixed(1)} horas'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Casos por Estado
              pw.Text(
                'Casos por Estado',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildPDFStatRow(
                        'Finalizados', '$finalizados casos', PdfColors.green),
                    pw.SizedBox(height: 8),
                    _buildPDFStatRow(
                        'En Progreso', '$enProceso casos', PdfColors.blue),
                    pw.SizedBox(height: 8),
                    _buildPDFStatRow(
                        'Pendientes', '$pendientes casos', PdfColors.grey),
                    if (cancelados > 0) ...[
                      pw.SizedBox(height: 8),
                      _buildPDFStatRow(
                          'Cancelados', '$cancelados casos', PdfColors.red),
                    ],
                    pw.SizedBox(height: 12),
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                    _buildPDFStatRow(
                        'TOTAL',
                        '${pendientes + enProceso + finalizados + cancelados} casos',
                        PdfColors.black,
                        isTotal: true),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Ranking Técnicos
              pw.Text(
                'Ranking Técnicos',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              if (ticketsPorTecnico.isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: ticketsPorTecnico.map((tecnico) {
                      final nombre = tecnico['nombre_tecnico'] ?? 'Sin nombre';
                      final tPendientes = tecnico['pendientes'] ?? 0;
                      final tEnProgreso = tecnico['en_progreso'] ?? 0;
                      final tFinalizados = tecnico['finalizados'] ?? 0;
                      final tCancelados = tecnico['cancelados'] ?? 0;
                      final total = tPendientes +
                          tEnProgreso +
                          tFinalizados +
                          tCancelados;

                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 12),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              '$nombre - Total: $total tickets',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Row(
                              children: [
                                if (tFinalizados > 0)
                                  pw.Text('✓ $tFinalizados Finalizados  ',
                                      style: const pw.TextStyle(
                                          color: PdfColors.green)),
                                if (tEnProgreso > 0)
                                  pw.Text('⏳ $tEnProgreso En progreso  ',
                                      style: const pw.TextStyle(
                                          color: PdfColors.blue)),
                                if (tPendientes > 0)
                                  pw.Text('⏸ $tPendientes Pendientes  ',
                                      style: const pw.TextStyle(
                                          color: PdfColors.grey)),
                                if (tCancelados > 0)
                                  pw.Text('✗ $tCancelados Cancelados  ',
                                      style: const pw.TextStyle(
                                          color: PdfColors.red)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Sistema de Tickets - Reporte generado automáticamente',
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPDFKPIRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  pw.Widget _buildPDFStatRow(String label, String value, PdfColor color,
      {bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar Estadísticas',
            onPressed: () {
              _exportStatistics();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTicketStats,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPIs Section
              _buildKPICards(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Casos por estado',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTasksStatsCard(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Ranking Técnicos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildTechnicianRanking(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    if (_ticketStats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final ticketsUltimos7Dias = _ticketStats!['tickets_ultimos_7_dias'] ?? 0;
    final ticketsResueltosUltimos7Dias =
        _ticketStats!['tickets_resueltos_ultimos_7_dias'] ?? 0;
    final tiempoPromedioResolucion =
        _ticketStats!['tiempo_promedio_resolucion']?.toDouble() ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Indicadores Clave',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                'Creados últimos 7 Días',
                ticketsUltimos7Dias.toString(),
                Icons.assignment,
                kPrimaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildKPICard(
                'Resueltos últimos 7 Días',
                ticketsResueltosUltimos7Dias.toString(),
                Icons.check_circle,
                kSuccessColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildKPICard(
          'Tiempo Promedio de Resolución',
          '${tiempoPromedioResolucion.toStringAsFixed(1)} horas',
          Icons.schedule,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
      int pendientes, int enProceso, int finalizados, int cancelados) {
    final total = pendientes + enProceso + finalizados + cancelados;
    if (total == 0) return [];

    return [
      PieChartSectionData(
        color: Colors.grey,
        value: pendientes.toDouble(),
        title: pendientes > 0 ? '$pendientes' : '',
        radius: 25,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.lightBlue,
        value: enProceso.toDouble(),
        title: enProceso > 0 ? '$enProceso' : '',
        radius: 25,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: kSuccessColor,
        value: finalizados.toDouble(),
        title: finalizados > 0 ? '$finalizados' : '',
        radius: 25,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      if (cancelados > 0)
        PieChartSectionData(
          color: Colors.red,
          value: cancelados.toDouble(),
          title: '$cancelados',
          radius: 25,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
    ];
  }

  Widget _buildTasksStatsCard() {
    if (_ticketStats == null) {
      return const Card(
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final ticketsPorEstado =
        _ticketStats!['tickets_por_estado'] as List<dynamic>? ?? [];

    // Calcular totales
    int pendientes = 0;
    int enProceso = 0;
    int finalizados = 0;
    int cancelados = 0;

    for (var item in ticketsPorEstado) {
      final count = item['count'] as int;

      switch (item['id_estado']) {
        case 1:
          pendientes = count;
          break;
        case 2:
          enProceso = count;
          break;
        case 3:
          finalizados = count;
          break;
        case 4:
          cancelados = count;
          break;
      }
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieChartSections(
                              pendientes, enProceso, finalizados, cancelados),
                          centerSpaceRadius: 35,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${pendientes + enProceso + finalizados + cancelados}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        Text(
                          'TOTAL',
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
                      _buildStatItem(
                          'Finalizados', '$finalizados casos', kSuccessColor),
                      const SizedBox(height: 10),
                      _buildStatItem(
                          'Pendientes', '$pendientes casos', Colors.grey),
                      const SizedBox(height: 10),
                      _buildStatItem(
                          'En progreso', '$enProceso casos', Colors.lightBlue),
                      if (cancelados > 0) ...[
                        const SizedBox(height: 10),
                        _buildStatItem(
                            'Cancelados', '$cancelados casos', Colors.red),
                      ],
                    ],
                  ),
                ),
              ],
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
    if (_ticketStats == null) {
      return const Card(
        elevation: 1,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final ticketsPorTecnico =
        _ticketStats!['tickets_por_tecnico_y_estado'] as List<dynamic>? ?? [];

    if (ticketsPorTecnico.isEmpty) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No hay datos de técnicos disponibles'),
          ),
        ),
      );
    }

    // Ordenar por total de tickets (descendente)
    final sortedTechnicians =
        List<Map<String, dynamic>>.from(ticketsPorTecnico);
    sortedTechnicians.sort((a, b) {
      final totalA = (a['pendientes'] ?? 0) +
          (a['en_progreso'] ?? 0) +
          (a['finalizados'] ?? 0) +
          (a['cancelados'] ?? 0);
      final totalB = (b['pendientes'] ?? 0) +
          (b['en_progreso'] ?? 0) +
          (b['finalizados'] ?? 0) +
          (b['cancelados'] ?? 0);
      return totalB.compareTo(totalA);
    });

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...sortedTechnicians.asMap().entries.map((entry) {
              final index = entry.key;
              final tecnico = entry.value;
              return Column(
                children: [
                  if (index > 0) const Divider(),
                  _buildTechnicianRankItem(tecnico),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicianRankItem(Map<String, dynamic> tecnico) {
    final nombre = tecnico['nombre_tecnico'] ?? 'Sin nombre';
    final pendientes = tecnico['pendientes'] ?? 0;
    final enProgreso = tecnico['en_progreso'] ?? 0;
    final finalizados = tecnico['finalizados'] ?? 0;
    final cancelados = tecnico['cancelados'] ?? 0;
    final total = pendientes + enProgreso + finalizados + cancelados;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: kPrimaryColor.withOpacity(0.1),
                child: Text(
                  nombre.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: kPrimaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      'Total: $total tickets',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 55),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (finalizados > 0)
                  _buildTicketBadge('$finalizados Finalizados', kSuccessColor),
                if (enProgreso > 0)
                  _buildTicketBadge(
                      '$enProgreso En progreso', Colors.lightBlue),
                if (pendientes > 0)
                  _buildTicketBadge('$pendientes Pendientes', Colors.grey),
                if (cancelados > 0)
                  _buildTicketBadge('$cancelados Cancelados', Colors.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
