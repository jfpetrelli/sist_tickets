import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/constants.dart';
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

class _AdminCaseListState extends State<AdminCaseList>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  bool _isSortAscending = true;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshTickets() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await Provider.of<TicketProvider>(context, listen: false)
        .fetchTickets(userProvider.user);
  }

  // Sorting order can be toggled from UI if needed; default is ascending

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
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
      int statusId, BoxConstraints constraints, List<Ticket> allTickets) {
    return RefreshIndicator(
      onRefresh: _refreshTickets,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Builder(
            builder: (context) {
              final normalizedQuery = _searchQuery.toLowerCase();

              final cases = allTickets
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
        final bool isSelected =
            caseItem.idCaso != null && caseItem.idCaso == widget.selectedCaseId;
        return InkWell(
          onTap: () {
            if (caseItem.idCaso != null) {
              widget.onCaseSelected(caseItem.idCaso!);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Card(
            elevation: 1,
            color: isSelected ? kSecondaryColor.withOpacity(0.10) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isSelected
                  ? const BorderSide(color: kSecondaryColor, width: 1.5)
                  : BorderSide.none,
            ),
            child: ListTile(
              selected: isSelected,
              selectedColor: kTextColor,
              tileColor: isSelected ? kSecondaryColor.withOpacity(0.06) : null,
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
    final isLoadingEmpty = context
        .select<TicketProvider, bool>((p) => p.isLoading && p.tickets.isEmpty);

    return Selector<TicketProvider, List<Ticket>>(
      selector: (_, p) => p.tickets,
      builder: (context, tickets, child) {
        if (isLoadingEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            _buildSearchField(),
            TabBar(
              controller: _tabController,
              labelColor: kPrimaryColor,
              unselectedLabelColor: Colors.black54,
              indicatorColor: kPrimaryColor,
              tabs: const [
                Tab(text: 'Pendientes', icon: Icon(Icons.hourglass_empty)),
                Tab(
                    text: 'En Proceso',
                    icon: Icon(Icons.settings_suggest_rounded)),
                Tab(text: 'Completados', icon: Icon(Icons.check_circle)),
              ],
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCasesTabView(1, constraints, tickets),
                      _buildCasesTabView(2, constraints, tickets),
                      _buildCasesTabView(3, constraints, tickets),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
