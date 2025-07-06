import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/models/ticket.dart';
import 'package:sist_tickets/providers/ticket_provider.dart';
import 'package:sist_tickets/screens/case_detail/case_detail_screen.dart';

// The widget is now a StatefulWidget.
// It holds the final properties that don't change over time, like the callback.
class CasesTab extends StatefulWidget {
  const CasesTab({
    super.key,
  });

  // StatefulWidget requires creating a State object.
  @override
  State<CasesTab> createState() => _CasesTabState();
}

// The State class holds the mutable state and the build logic.
class _CasesTabState extends State<CasesTab> {
  // initState is called once when the widget is inserted into the widget tree.
  // It's the perfect place for one-time initialization like fetching data.
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // This schedules a callback to be executed after the first frame is rendered.
    // It safely calls the provider to fetch the initial list of tickets.

    _searchController = TextEditingController();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
    });
  }

  @override
  void dispose() {
    // Dispose of the controller to free up resources.
    _searchController.dispose();
    super.dispose();
  }

  // This function will be called when the user pulls down to refresh.
  Future<void> _refreshTickets() async {
    await Provider.of<TicketProvider>(context, listen: false).fetchTickets();
  }

  @override
  Widget build(BuildContext context) {
    // The RefreshIndicator widget adds pull-to-refresh functionality.
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _buildSearchField(),
          const TabBar(
            labelColor: kPrimaryColor,
            unselectedLabelColor: Colors.black54,
            indicatorColor: kPrimaryColor,
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
                    _buildCasesTabView(1, constraints), // Pendientes
                    _buildCasesTabView(2, constraints), // En Proceso
                    _buildCasesTabView(3, constraints), // Completados
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasesTabView(int statusId, BoxConstraints constraints) {
    return RefreshIndicator(
      onRefresh: _refreshTickets,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Consumer<TicketProvider>(
            builder: (context, value, child) {
              if (value.isLoading && value.tickets.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final normalizedQuery = _searchQuery.toLowerCase();

              final cases = value.tickets
                  .where((ticket) => ticket.idEstado == statusId)
                  .where((ticket) {
                // Add this second .where for filtering
                // If search is empty, show all tickets for this tab
                if (normalizedQuery.isEmpty) return true;

                // Check against multiple fields
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
              // If no cases match the search query, show a message
              if (cases.isEmpty) {
                return const Center(
                  child: Text(
                    'No se encontraron casos que coincidan con la búsqueda.',
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
          // Add a clear button
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

  // This helper method is now part of the State class.
  Widget _buildCasesList(List<Ticket> cases) {
    return Column(
      // Removed 'spacing: 5,' as Column doesn't have a 'spacing' property. Use SizedBox if needed.
      children: cases.map((caseItem) {
        // Format the date as dd/MM
        String formattedDate = '';
        if (caseItem.fecha != null) {
          final date = caseItem.fecha;
          formattedDate =
              '${date?.day.toString().padLeft(2, '0')}/${date?.month.toString().padLeft(2, '0')}';
        }
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CaseDetailScreen(caseId: caseItem.idCaso.toString()),
              ),
            );
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
                    color: kPrimaryColor,
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
              // Add the date at the far right
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
}
