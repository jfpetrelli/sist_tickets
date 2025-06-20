import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/model/ticket.dart';
import 'package:sist_tickets/provider/ticket_provider.dart';

class CasesContent extends StatelessWidget {
  final ValueChanged<String> onShowCaseDetail;

  const CasesContent({
    super.key,
    required this.onShowCaseDetail,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Casos',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Consumer<TicketProvider>(builder: (context, value, child) {
            if (value.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final pendingCases = value.tickets.toList();
            return _buildCasesList(pendingCases);
          })
        ],
      ),
    );
  }

  Widget _buildCasesList(List<Ticket> cases) {
    return Column(
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
                onPressed: () => onShowCaseDetail(caseItem.idCaso
                    .toString()), //TODO ver como hacerlo statefull
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
                caseItem.idCliente.toString(),
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

class _CaseItem {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final VoidCallback onTap;

  const _CaseItem({
    required this.title,
    required this.subtitle,
    this.isCompleted = false,
    required this.onTap,
  });
}
