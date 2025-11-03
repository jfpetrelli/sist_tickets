import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/models/ticket.dart';
import 'package:sist_tickets/providers/ticket_provider.dart';
import 'package:sist_tickets/providers/user_provider.dart';

class AdminCaseList extends StatefulWidget {
  final Function(int) onCaseSelected;
  final int? selectedCaseId;

  const AdminCaseList({
    super.key,
    required this.onCaseSelected,
    this.selectedCaseId,
  });

  @override
  State<AdminCaseList> createState() => _AdminCaseListState();
}

class _AdminCaseListState extends State<AdminCaseList> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  bool _isSortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ticketProvider =
          Provider.of<TicketProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      ticketProvider.fetchTickets(userProvider.user);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshTickets() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await Provider.of<TicketProvider>(context, listen: false)
        .fetchTickets(userProvider.user);
  }

  void _toggleSortOrder() {
    setState(() {
      _isSortAscending = !_isSortAscending;
    });
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
    );
  }

  Widget _buildCasesTabView(
      int statusId, BoxConstraints constraints, TicketProvider value) {
    return RefreshIndicator(
      onRefresh: _refreshTickets,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Builder(
            builder: (context) {
              if (value.isLoading && value.tickets.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final normalizedQuery = _searchQuery.toLowerCase();

              final cases = value.tickets
                  .where((ticket) => ticket.idEstado == statusId)
                  .where((ticket) {
                if (normalizedQuery.isEmpty) return true;
                final id = '#${ticket.idCaso.toString()}';
                final title = ticket.titulo.toLowerCase();
                final client =
                    (ticket.cliente?.razonSocial ?? '').toLowerCase();
                final tech = (ticket.tecnico ?? '').toLowerCase();

                return id.contains(normalizedQuery) ||
                    title.contains(normalizedQuery) ||
                    client.contains(normalizedQuery) ||
                    tech.contains(normalizedQuery);
              }).toList();

              cases.sort((a, b) {
                if (a.fecha == null && b.fecha == null) return 0;
                if (a.fecha == null) return 1;
                if (b.fecha == null) return -1;
                return _isSortAscending
                    ? a.fecha!.compareTo(b.fecha!)
                    : b.fecha!.compareTo(a.fecha!);
              });

              if (cases.isEmpty) {
                return const Center(
                  child: Text(
                    'No se encontraron casos que coincidan.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                );
              }
              return _buildCasesList(cases);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCasesList(List<Ticket> cases) {
    return Column(
      children: cases.map((caseItem) {
        String formattedDate = '';
        if (caseItem.fecha != null) {
          final date = caseItem.fecha;
          formattedDate =
              '${date?.day.toString().padLeft(2, '0')}/${date?.month.toString().padLeft(2, '0')}';
        }
        return InkWell(
          onTap: () {
            if (caseItem.idCaso != null) {
              widget.onCaseSelected(caseItem.idCaso!);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -4),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              leading: Container(
                alignment: Alignment.center,
                width: 40,
                child: Text(
                  '#${caseItem.idCaso.toString()}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              title: Text(
                caseItem.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${caseItem.cliente?.razonSocial ?? ''} - (${caseItem.idPersonalAsignado.toString()}) ${caseItem.tecnico ?? ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              trailing: Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TicketProvider>(
      builder: (context, ticketProvider, child) {
        if (ticketProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              _buildSearchField(),
              const TabBar(
                labelColor: Colors.orange,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.orange,
                tabs: [
                  Tab(text: 'Pendientes'),
                  Tab(text: 'En Proceso'),
                  Tab(text: 'Completados'),
                ],
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return TabBarView(
                      children: [
                        _buildCasesTabView(1, constraints, ticketProvider),
                        _buildCasesTabView(2, constraints, ticketProvider),
                        _buildCasesTabView(3, constraints, ticketProvider),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
