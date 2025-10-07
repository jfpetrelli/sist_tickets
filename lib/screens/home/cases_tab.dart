import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/models/ticket.dart';
import 'package:sist_tickets/providers/ticket_provider.dart';
import 'package:sist_tickets/providers/user_provider.dart';
import 'package:sist_tickets/screens/case_detail/case_detail_screen.dart';
import 'package:table_calendar/table_calendar.dart';

class CasesTab extends StatefulWidget {
  const CasesTab({super.key});

  @override
  State<CasesTab> createState() => _CasesTabState();
}

class _CasesTabState extends State<CasesTab> {
  late final TextEditingController _searchController;
  String _searchQuery = '';
  bool _isSortAscending = true;
  bool _isCalendarView = false;

  late final ValueNotifier<List<Ticket>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier([]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ticketProvider =
          Provider.of<TicketProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      ticketProvider.fetchTickets(userProvider.user).then((_) {
        _selectedEvents.value =
            _getEventsForDay(_selectedDay!, ticketProvider.tickets);
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _selectedEvents.dispose();
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

  void _toggleView() {
    setState(() {
      _isCalendarView = !_isCalendarView;
    });
  }

  List<Ticket> _getEventsForDay(DateTime day, List<Ticket> allTickets) {
    return allTickets.where((ticket) {
      if (ticket.fechaTentativaInicio == null) return false;
      return isSameDay(ticket.fechaTentativaInicio, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ticketProvider = Provider.of<TicketProvider>(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isCalendarView ? 'Calendario de Casos' : 'Casos'),
          actions: [
            IconButton(
              tooltip: _isCalendarView ? 'Ver Lista' : 'Ver Calendario',
              icon: Icon(_isCalendarView ? Icons.list : Icons.calendar_today),
              onPressed: _toggleView,
            ),
          ],
          bottom: _isCalendarView
              ? null
              : const TabBar(
                  labelColor: kPrimaryColor,
                  unselectedLabelColor: Colors.black54,
                  indicatorColor: kPrimaryColor,
                  tabs: [
                    Tab(text: 'Pendientes'),
                    Tab(text: 'En Proceso'),
                    Tab(text: 'Completados'),
                  ],
                ),
        ),
        body: Column(
          children: [
            if (!_isCalendarView) _buildSearchField(),
            Expanded(
              child: _isCalendarView
                  ? _buildCalendarView(ticketProvider.tickets)
                  : LayoutBuilder(
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
        floatingActionButton: _isCalendarView
            ? null
            : FloatingActionButton(
                onPressed: _toggleSortOrder,
                tooltip: 'Ordenar por fecha',
                shape: const CircleBorder(),
                backgroundColor: kPrimaryColor,
                child: Icon(
                  _isSortAscending ? Icons.arrow_downward : Icons.arrow_upward,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildCalendarView(List<Ticket> allTickets) {
    return Column(
      children: [
        TableCalendar<Ticket>(
          locale: 'es_ES', // For Spanish locale
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2050, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Mes',
            CalendarFormat.twoWeeks: '2 Semanas',
            CalendarFormat.week: 'Semana',
          },
          eventLoader: (day) => _getEventsForDay(day, allTickets),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _selectedEvents.value = _getEventsForDay(selectedDay, allTickets);
            }
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const SizedBox(height: 8.0),
        const Divider(height: 1, indent: 12, endIndent: 12),
        Expanded(
          child: _buildEventList(),
        ),
      ],
    );
  }

  Widget _buildEventList() {
    return ValueListenableBuilder<List<Ticket>>(
      valueListenable: _selectedEvents,
      builder: (context, value, _) {
        if (value.isEmpty) {
          return const Center(
            child: Text(
              "No hay casos para este día.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }
        // We wrap your list in a SingleChildScrollView to make it scrollable
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildCasesList(value),
        );
      },
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
