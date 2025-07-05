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
  @override
  void initState() {
    super.initState();
    // This schedules a callback to be executed after the first frame is rendered.
    // It safely calls the provider to fetch the initial list of tickets.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TicketProvider>(context, listen: false).fetchTickets();
    });
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
                    // Pendientes (idEstado == 1)
                    RefreshIndicator(
                      onRefresh: _refreshTickets,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 4.0),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Consumer<TicketProvider>(
                            builder: (context, value, child) {
                              if (value.isLoading && value.tickets.isEmpty) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final cases = value.tickets
                                  .where((ticket) => ticket.idEstado == 1)
                                  .toList();
                              return _buildCasesList(cases);
                            },
                          ),
                        ),
                      ),
                    ),
                    // En Proceso (idEstado == 2)
                    RefreshIndicator(
                      onRefresh: _refreshTickets,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 4.0),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Consumer<TicketProvider>(
                            builder: (context, value, child) {
                              if (value.isLoading && value.tickets.isEmpty) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final cases = value.tickets
                                  .where((ticket) => ticket.idEstado == 2)
                                  .toList();
                              return _buildCasesList(cases);
                            },
                          ),
                        ),
                      ),
                    ),
                    // Finalizados (idEstado == 3)
                    RefreshIndicator(
                      onRefresh: _refreshTickets,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 4.0),
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: constraints.maxHeight),
                          child: Consumer<TicketProvider>(
                            builder: (context, value, child) {
                              if (value.isLoading && value.tickets.isEmpty) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              final cases = value.tickets
                                  .where((ticket) => ticket.idEstado == 3)
                                  .toList();
                              return _buildCasesList(cases);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // This helper method is now part of the State class.
  Widget _buildCasesList(List<Ticket> cases) {
    return Column(
      spacing: 5,
      // The list is built dynamically from the 'cases' data.
      children: cases.map((caseItem) {
        return InkWell(
          //podemos tener quick options con un long press
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
            //margin: EdgeInsets.only(bottom: 18.0),
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
                width: 40, // Optional: set a fixed width if needed
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
                style: TextStyle(
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
            ),
          ),
        );
      }).toList(),
    );
  }
}
