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

  // All the building logic and helper methods are moved here.
  @override
  Widget build(BuildContext context) {
    // The RefreshIndicator widget adds pull-to-refresh functionality.
    return RefreshIndicator(
      onRefresh: _refreshTickets,
      child: SingleChildScrollView(
        // Ensures the scroll view is always scrollable, allowing refresh even with few items.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: Text(
                'Casos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // The Consumer listens for changes in TicketProvider and rebuilds the list.
            Consumer<TicketProvider>(builder: (context, value, child) {
              // Show a loading spinner only on the initial load when the list is empty.
              if (value.isLoading && value.tickets.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              // Data from the provider is used to build the list.
              final pendingCases = value.tickets.toList();
              return _buildCasesList(pendingCases);
            })
          ],
        ),
      ),
    );
  }

  // This helper method is now part of the State class.
  Widget _buildCasesList(List<Ticket> cases) {
    return Column(
      // The list is built dynamically from the 'cases' data.
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              leading: ElevatedButton(
                // To access the properties of the StatefulWidget, we use `widget.`
                onPressed: () {
                  // En lugar de llamar a un callback, navegamos a la nueva pantalla
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CaseDetailScreen(caseId: caseItem.idCaso.toString()),
                    ),
                  );
                },
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
                caseItem.cliente?.razonSocial ?? 'Cliente no disponible',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                caseItem.titulo,
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
