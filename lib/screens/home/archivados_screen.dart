import 'package:flutter/material.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/models/ticket.dart';
import 'package:sist_tickets/api/api_service.dart';
import 'package:sist_tickets/screens/case_detail/case_detail_screen.dart';

class ArchivadosScreen extends StatefulWidget {
  const ArchivadosScreen({super.key});

  @override
  State<ArchivadosScreen> createState() => _ArchivadosScreenState();
}

class _ArchivadosScreenState extends State<ArchivadosScreen> {
  final ApiService _apiService = ApiService();
  List<Ticket> _tickets = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchArchivados();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchArchivados() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getTicketsByEstado(4);
      setState(() {
        _tickets = data.map((d) => Ticket.fromJson(d)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar archivados: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _searchQuery.toLowerCase();
    final filtered = _tickets.where((ticket) {
      if (normalizedQuery.isEmpty) return true;
      final id = '#${ticket.idCaso.toString()}';
      final title = ticket.titulo.toLowerCase();
      final client = (ticket.cliente?.razonSocial ?? '').toLowerCase();
      final tech = (ticket.tecnico ?? '').toLowerCase();
      return id.contains(normalizedQuery) ||
          title.contains(normalizedQuery) ||
          client.contains(normalizedQuery) ||
          tech.contains(normalizedQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archivados'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchArchivados,
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por ID, título, cliente...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(
                        child: Text('No se encontraron tickets archivados.'),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchArchivados,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final ticket = filtered[index];
                            String formattedDate = '';
                            if (ticket.fecha != null) {
                              final date = ticket.fecha!;
                              formattedDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
                            }
                            return InkWell(
                              onTap: () async {
                                // Espera a que el usuario vuelva del detalle y recarga la lista
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CaseDetailScreen(caseId: ticket.idCaso.toString()),
                                  ),
                                );
                                // Al volver, refrescar los archivados para reflejar cambios de estado
                                if (mounted) {
                                  _fetchArchivados();
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Card(
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                child: ListTile(
                                  dense: true,
                                  visualDensity: const VisualDensity(vertical: -4),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  leading: Container(
                                    alignment: Alignment.center,
                                    width: 40,
                                    child: Text(
                                      '#${ticket.idCaso.toString()}',
                                      style: const TextStyle(
                                        color: kPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    ticket.titulo,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    '${ticket.cliente?.razonSocial ?? ''} - (${ticket.idPersonalAsignado.toString()}) ${ticket.tecnico ?? ''}',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  trailing: Text(
                                    formattedDate,
                                    style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
