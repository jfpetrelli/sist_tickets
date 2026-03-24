// lib/screens/admin_web/calendar_screen.dart
//
// Google-Calendar-style weekly time grid with drag-to-reschedule.
// Web-only:  kIsWeb guard is applied at the Scaffold level.

import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:sist_tickets/api/api_service.dart';
import 'package:sist_tickets/constants.dart';
import 'package:sist_tickets/models/ticket.dart';
import 'package:sist_tickets/models/ticket_visita.dart';
import 'package:sist_tickets/models/usuario.dart';
import 'package:sist_tickets/providers/user_provider.dart';
import 'package:sist_tickets/providers/user_list_provider.dart';
import 'package:sist_tickets/providers/visita_provider.dart';
import 'package:sist_tickets/screens/case_detail/case_detail_screen.dart';

// ─────────────────────────── Layout constants ─────────────────────────────── //

const double _kHourHeight = 64.0; // pixels per hour
const double _kTimeColWidth = 56.0; // left time-label column
const int _kStartHour = 0;
const int _kEndHour = 24;
const double _kGridHeight = (_kEndHour - _kStartHour) * _kHourHeight;
const double _kDayHeaderHeight = 56.0;
const double _kMinEventHeight = 24.0;

// ─────────────────────────── Color helpers ────────────────────────────────── //

const _estadoColors = {
  'pendiente': Color(0xFFFFB74D),
  'confirmada': Color(0xFF42A5F5),
  'completada': Color(0xFF66BB6A),
  'cancelada': Color(0xFFEF5350),
};

const _estadoLabels = {
  'pendiente': 'Pendiente',
  'confirmada': 'Confirmada',
  'completada': 'Completada',
  'cancelada': 'Cancelada',
};

// ════════════════════════════════════════════════════════════════════════════ //
// CalendarScreen                                                               //
// ════════════════════════════════════════════════════════════════════════════ //

// ─────────────────────────── View mode ──────────────────────────────────── //

enum _CalendarViewMode { week, day }

// ════════════════════════════════════════════════════════════════════════════ //

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // ── State ─────────────────────────────────────────────────────────────── //
  late DateTime _weekStart; // always a Sunday
  final _scrollCtrl = ScrollController();

  /// One GlobalKey per day column — used to convert drop global offset → time.
  final _colKeys = List.generate(7, (_) => GlobalKey());

  // ── Day-view state ────────────────────────────────────────────────────── //
  _CalendarViewMode _viewMode = _CalendarViewMode.week;
  DateTime _selectedDay = DateTime.now();

  /// One GlobalKey per technician column — used in day-view drop calculation.
  final List<GlobalKey> _techKeys = [];

  /// Case-ID → title cache, populated after each calendar fetch.
  final Map<int, String> _caseTitles = {};

  // ── Lifecycle ─────────────────────────────────────────────────────────── //

  @override
  void initState() {
    super.initState();
    _weekStart = _sundayOf(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCalendar();
      context.read<UserListProvider>().fetchUsers(userType: 1);
      // Scroll to 7 AM
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(7 * _kHourHeight);
      }
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────── //

  /// Sunday of the week that contains [date].
  DateTime _sundayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday % 7));
  }

  DateTime get _weekEnd => _weekStart.add(const Duration(days: 6));

  DateTime _dayAt(int colIndex) =>
      _weekStart.add(Duration(days: colIndex));

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  List<TicketVisita> _visitsForDay(DateTime day) =>
      context.read<VisitaProvider>().visitas.where((v) {
        final d = v.fechaInicio;
        return d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
      }).toList();

  void _loadCalendar() {
    final user = context.read<UserProvider>().user;
    final DateTime rangeStart;
    final DateTime rangeEnd;
    if (_viewMode == _CalendarViewMode.week) {
      rangeStart = _weekStart;
      rangeEnd = _weekEnd;
    } else {
      rangeStart = DateTime(
          _selectedDay.year, _selectedDay.month, _selectedDay.day);
      rangeEnd = DateTime(
          _selectedDay.year, _selectedDay.month, _selectedDay.day, 23, 59, 59);
    }
    context.read<VisitaProvider>().fetchCalendar(
          user,
          rangeStart,
          rangeEnd,
        ).then((_) => _fetchAndCacheTitles());
  }

  /// Fetches the case title for every unique case ID in the loaded visits
  /// and stores them in [_caseTitles] so the calendar blocks can display them.
  Future<void> _fetchAndCacheTitles() async {
    if (!mounted) return;
    final visitas = context.read<VisitaProvider>().visitas;
    final uniqueIds =
        visitas.map((v) => v.idCaso).toSet().toList();
    final apiService = context.read<ApiService>();

    await Future.wait(uniqueIds.map((caseId) async {
      if (_caseTitles.containsKey(caseId)) return; // already cached
      try {
        final data = await apiService.getTicketById(caseId.toString());
        final title = data['titulo'] as String?;
        if (title != null && mounted) {
          setState(() => _caseTitles[caseId] = title);
        }
      } catch (_) {/* silently skip */}
    }));
  }

  void _goToToday() {
    setState(() {
      _weekStart = _sundayOf(DateTime.now());
      _selectedDay = DateTime.now();
    });
    _loadCalendar();
    // Scroll to current time
    final now = DateTime.now();
    final targetOffset =
        ((now.hour - 1) * _kHourHeight).clamp(0.0, _kGridHeight);
    _scrollCtrl.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  void _prevWeek() {
    setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
    _loadCalendar();
  }

  void _nextWeek() {
    setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));
    _loadCalendar();
  }

  void _prevDay() {
    setState(
        () => _selectedDay = _selectedDay.subtract(const Duration(days: 1)));
    _loadCalendar();
  }

  void _nextDay() {
    setState(() => _selectedDay = _selectedDay.add(const Duration(days: 1)));
    _loadCalendar();
  }

  // ── Drag & Drop ───────────────────────────────────────────────────────── //

  /// Called when a visit is dropped on [day] column.
  void _onDropOnDay(
    DateTime day,
    int colIndex,
    DragTargetDetails<TicketVisita> details,
  ) {
    final box =
        _colKeys[colIndex].currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    // Convert global drop offset to local Y within the day column.
    // The RenderBox transform already accounts for scroll position.
    final localY = box.globalToLocal(details.offset).dy;

    // Snap drop position to 15-minute slots.
    final rawMinutes = (localY / _kHourHeight * 60).round();
    final snappedMinutes = ((rawMinutes / 15).round() * 15).clamp(0, 23 * 60);
    final hours = snappedMinutes ~/ 60;
    final minutes = snappedMinutes % 60;

    final visita = details.data;
    final duration = visita.fechaFin.difference(visita.fechaInicio);
    final newStart = DateTime(day.year, day.month, day.day, hours, minutes);
    final newEnd = newStart.add(duration);

    _moveVisita(visita, newStart, newEnd);
  }

  Future<void> _moveVisita(
      TicketVisita visita, DateTime newStart, DateTime newEnd) async {
    await _moveVisitaWithTech(visita, newStart, newEnd, null);
  }

  Future<void> _moveVisitaWithTech(
    TicketVisita visita,
    DateTime newStart,
    DateTime newEnd,
    int? newTechId,
  ) async {
    final data = {
      ...visita.toJson(),
      'fecha_inicio': newStart.toIso8601String(),
      'fecha_fin': newEnd.toIso8601String(),
      if (newTechId != null) 'id_personal_asignado': newTechId,
    };
    final ok =
        await context.read<VisitaProvider>().updateVisita(visita.idVisita!, data);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Visita reprogramada' : 'Error al mover la visita'),
        backgroundColor: ok ? kSuccessColor : kErrorColor,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  /// Called when a visit is dropped onto a technician column in day view.
  void _onDropOnTechColumn(
    int techIndex,
    Usuario tech,
    DragTargetDetails<TicketVisita> details,
  ) {
    final box =
        _techKeys[techIndex].currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final localY = box.globalToLocal(details.offset).dy;
    final rawMinutes = (localY / _kHourHeight * 60).round();
    final snappedMinutes = ((rawMinutes / 15).round() * 15).clamp(0, 23 * 60);
    final hours = snappedMinutes ~/ 60;
    final minutes = snappedMinutes % 60;

    final visita = details.data;
    final duration = visita.fechaFin.difference(visita.fechaInicio);
    final newStart = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day, hours, minutes);
    final newEnd = newStart.add(duration);
    _moveVisitaWithTech(visita, newStart, newEnd, tech.idPersonal);
  }

  // ── Create / Edit dialog ──────────────────────────────────────────────── //

  void _showVisitaForm({TicketVisita? visita, DateTime? initialDate, int? lockedCaseId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => _VisitaFormDialog(
        visita: visita,
        initialDate: initialDate,
        lockedCaseId: lockedCaseId,
        onSaved: (data) async {
          Navigator.pop(dialogCtx);
          final provider = context.read<VisitaProvider>();
          final bool ok;
          if (visita == null) {
            ok = await provider.createVisita(data);
          } else {
            ok = await provider.updateVisita(visita.idVisita!, data);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(ok
                  ? (visita == null
                      ? 'Visita creada'
                      : 'Visita actualizada')
                  : (provider.errorMessage ?? 'Error al guardar')),
              backgroundColor: ok ? kSuccessColor : kErrorColor,
            ));
          }
        },
      ),
    );
  }

  void _confirmDelete(TicketVisita v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar visita'),
        content:
            Text('¿Eliminar la visita del caso #${v.idCaso}? No se puede deshacer.'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: kPrimaryColor),
            child: const Text('Eliminar'),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok =
                  await context.read<VisitaProvider>().deleteVisita(v.idVisita!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      ok ? 'Visita eliminada' : 'Error al eliminar'),
                  backgroundColor: ok ? kSuccessColor : kErrorColor,
                ));
              }
            },
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────── //

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.user;
    final isAdmin = currentUser?.idTipo == 2;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVisitaForm(),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Visita'),
        elevation: 3,
      ),
      body: Column(
        children: [
          _buildTopBar(isAdmin),
          if (_viewMode == _CalendarViewMode.week)
            _buildDayHeaders()
          else
            Consumer<UserListProvider>(
              builder: (_, ulp, __) => _buildTechnicianHeaders(ulp.users),
            ),
          Expanded(
            child: Consumer<VisitaProvider>(
              builder: (__, visitaProv, _) {
                final technicians = context.read<UserListProvider>().users;
                // Keep the scroll view always mounted so _scrollCtrl
                // never loses its client and the 7 AM offset is preserved.
                return Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollCtrl,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTimeAxis(),
                          Expanded(
                            child: _viewMode == _CalendarViewMode.week
                                ? _buildWeekGrid()
                                : _buildTechDayGrid(technicians),
                          ),
                        ],
                      ),
                    ),
                    if (visitaProv.isLoading)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x55FFFFFF),
                          child: Center(child: CircularProgressIndicator()),
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

  // ── Top bar ───────────────────────────────────────────────────────────── //

  Widget _buildTopBar(bool isAdmin) {
    // Compute the label based on the current view mode
    final String label;
    if (_viewMode == _CalendarViewMode.week) {
      final weekFmt = DateFormat('MMMM yyyy', 'es');
      label = _weekStart.month == _weekEnd.month
          ? weekFmt.format(_weekStart)
          : '${DateFormat('d MMM', 'es').format(_weekStart)} – '
              '${DateFormat('d MMM yyyy', 'es').format(_weekEnd)}';
    } else {
      label = DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'es').format(_selectedDay);
    }

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          // Today button
          OutlinedButton(
            onPressed: _goToToday,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade400),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Hoy',
                style: TextStyle(color: Colors.black87, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          // Prev / Next arrows (context-sensitive)
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            onPressed: _viewMode == _CalendarViewMode.week
                ? _prevWeek
                : _prevDay,
            tooltip: _viewMode == _CalendarViewMode.week
                ? 'Semana anterior'
                : 'Día anterior',
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            onPressed: _viewMode == _CalendarViewMode.week
                ? _nextWeek
                : _nextDay,
            tooltip: _viewMode == _CalendarViewMode.week
                ? 'Semana siguiente'
                : 'Día siguiente',
          ),
          const SizedBox(width: 8),
          // Date label
          Text(
            label,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          const Spacer(),
          // View mode toggle
          SegmentedButton<_CalendarViewMode>(
            segments: const [
              ButtonSegment(
                value: _CalendarViewMode.week,
                icon: Icon(Icons.view_week_outlined, size: 16),
                label: Text('Semana', style: TextStyle(fontSize: 12)),
              ),
              ButtonSegment(
                value: _CalendarViewMode.day,
                icon: Icon(Icons.view_day_outlined, size: 16),
                label: Text('Día', style: TextStyle(fontSize: 12)),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (newSelection) {
              final next = newSelection.first;
              if (next == _viewMode) return;
              setState(() => _viewMode = next);
              _loadCalendar();
            },
          ),
        ],
      ),
    );
  }

  // ── Day header row ─────────────────────────────────────────────────────── //

  Widget _buildDayHeaders() {
    const dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return Container(
      height: _kDayHeaderHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(width: _kTimeColWidth), // aligns with time axis
          ...List.generate(7, (i) {
            final day = _dayAt(i);
            final today = _isToday(day);
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNames[i].toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          today ? kPrimaryColor : Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: today
                        ? const BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                          )
                        : null,
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: today ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Time-label axis ───────────────────────────────────────────────────── //

  Widget _buildTimeAxis() {
    return SizedBox(
      width: _kTimeColWidth,
      height: _kGridHeight,
      child: Stack(
        children: List.generate(_kEndHour - _kStartHour, (i) {
          final hour = _kStartHour + i;
          if (hour == 0) return const SizedBox.shrink();
          return Positioned(
            top: i * _kHourHeight - 7,
            left: 0,
            right: 4,
            child: Text(
              _formatHour(hour),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }),
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour < 12 ? 'a.m.' : 'p.m.';
    return '$h $ampm';
  }

  // ── Week grid (7 day columns side by side) ────────────────────────────── //

  Widget _buildWeekGrid() {
    return SizedBox(
      height: _kGridHeight,
      child: Row(
        children: List.generate(7, (i) {
          return Expanded(child: _buildDayColumn(i));
        }),
      ),
    );
  }

  // ── Technician header row (day view) ─────────────────────────────────── //

  Widget _buildTechnicianHeaders(List<Usuario> technicians) {
    if (technicians.isEmpty) {
      return Container(
        height: _kDayHeaderHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        alignment: Alignment.center,
        child: const Text('Sin técnicos',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return Container(
      height: _kDayHeaderHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          SizedBox(width: _kTimeColWidth), // aligns with time axis
          ...technicians.map((tech) {
            final initials = tech.nombre
                .split(' ')
                .where((w) => w.isNotEmpty)
                .take(2)
                .map((w) => w[0].toUpperCase())
                .join();
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: kPrimaryColor.withOpacity(0.15),
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tech.nombre,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Day grid: one column per technician (day view) ───────────────────── //

  Widget _buildTechDayGrid(List<Usuario> technicians) {
    if (technicians.isEmpty) {
      return const SizedBox(
        height: _kGridHeight,
        child: Center(
          child: Text('No hay técnicos disponibles',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    // Grow the key list as needed
    while (_techKeys.length < technicians.length) {
      _techKeys.add(GlobalKey());
    }

    final currentUser = context.read<UserProvider>().user;
    final isAdmin = currentUser?.idTipo == 2;
    final isToday = _isToday(_selectedDay);

    return SizedBox(
      height: _kGridHeight,
      child: Row(
        children: List.generate(technicians.length, (index) {
          final tech = technicians[index];
          final techVisits =
              context.read<VisitaProvider>().visitas.where((v) {
            final d = v.fechaInicio;
            return d.year == _selectedDay.year &&
                d.month == _selectedDay.month &&
                d.day == _selectedDay.day &&
                v.idPersonalAsignado == tech.idPersonal;
          }).toList();

          return Expanded(
            child: DragTarget<TicketVisita>(
              onWillAcceptWithDetails: (_) => true,
              onAcceptWithDetails: (details) =>
                  _onDropOnTechColumn(index, tech, details),
              builder: (ctx, candidates, rejected) {
                final isHighlighted = candidates.isNotEmpty;
                return Stack(
                  children: [
                    SizedBox(
                      key: _techKeys[index],
                      width: double.infinity,
                      height: _kGridHeight,
                      child: _buildColumnBackground(isToday, isHighlighted),
                    ),
                    if (isToday) _buildNowIndicator(),
                    ..._layoutVisits(
                        techVisits, index, currentUser, isAdmin),
                  ],
                );
              },
            ),
          );
        }),
      ),
    );
  }

  // ── Single day column ─────────────────────────────────────────────────── //

  Widget _buildDayColumn(int colIndex) {
    final day = _dayAt(colIndex);
    final visits = _visitsForDay(day);
    final today = _isToday(day);
    final currentUser = context.read<UserProvider>().user;
    final isAdmin = currentUser?.idTipo == 2;

    return DragTarget<TicketVisita>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) =>
          _onDropOnDay(day, colIndex, details),
      builder: (ctx, candidates, rejected) {
        final isHighlighted = candidates.isNotEmpty;
        return Stack(
          children: [
            // ── Background / grid lines key anchor ── //
            SizedBox(
              key: _colKeys[colIndex],
              width: double.infinity,
              height: _kGridHeight,
              child: _buildColumnBackground(today, isHighlighted),
            ),

            // ── Current-time red line (today only) ─── //
            if (today) _buildNowIndicator(),

            // ── Visit event blocks ──────────────────── //
            ..._layoutVisits(visits, colIndex, currentUser, isAdmin),
          ],
        );
      },
    );
  }

  Widget _buildColumnBackground(bool today, bool highlighted) {
    return CustomPaint(
      painter: _GridLinePainter(
        hourHeight: _kHourHeight,
        startHour: _kStartHour,
        endHour: _kEndHour,
        todayBackground:
            today ? kPrimaryColor.withOpacity(0.03) : null,
        highlightBackground:
            highlighted ? kPrimaryColor.withOpacity(0.07) : null,
      ),
    );
  }

  Widget _buildNowIndicator() {
    final now = DateTime.now();
    final top = ((now.hour - _kStartHour) + now.minute / 60.0) * _kHourHeight;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFFEA4335),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
                height: 1.5, color: const Color(0xFFEA4335)),
          ),
        ],
      ),
    );
  }

  // ── Visit block layout (simple overlap handling) ─────────────────────── //

  List<Widget> _layoutVisits(
    List<TicketVisita> visits,
    int colIndex,
    Usuario? currentUser,
    bool isAdmin,
  ) {
    if (visits.isEmpty) return [];

    // Group overlapping visits and assign column slots
    visits.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));

    // Simple greedy column assignment
    final columns = <List<TicketVisita>>[];
    for (final v in visits) {
      bool placed = false;
      for (final col in columns) {
        if (col.isEmpty ||
            col.last.fechaFin.isBefore(v.fechaInicio) ||
            col.last.fechaFin.isAtSameMomentAs(v.fechaInicio)) {
          col.add(v);
          placed = true;
          break;
        }
      }
      if (!placed) columns.add([v]);
    }

    final totalCols = columns.length;
    final widgets = <Widget>[];

    for (int c = 0; c < totalCols; c++) {
      for (final v in columns[c]) {
        final canEdit =
            isAdmin || v.idPersonalAsignado == currentUser?.idPersonal;
        widgets.add(_buildVisitBlock(
          v, colIndex, c, totalCols, canEdit, currentUser, isAdmin));
      }
    }
    return widgets;
  }

  Widget _buildVisitBlock(
    TicketVisita v,
    int colIndex,
    int slotIndex,
    int totalSlots,
    bool canEdit,
    Usuario? currentUser,
    bool isAdmin,
  ) {
    final startMins =
        (v.fechaInicio.hour - _kStartHour) * 60 + v.fechaInicio.minute;
    final endMins =
        (v.fechaFin.hour - _kStartHour) * 60 + v.fechaFin.minute;
    final durationMins = max(endMins - startMins, 15); // min 15 min height

    final top = startMins / 60.0 * _kHourHeight;
    final height =
        max(durationMins / 60.0 * _kHourHeight, _kMinEventHeight);

    const hPad = 2.0;
    final color = _estadoColors[v.estadoVisita] ?? Colors.grey;

    final card = _VisitCard(
      visita: v,
      color: color,
      height: height,
      titleOverride: _caseTitles[v.idCaso],
      onTap: canEdit
          ? () => _showVisitaForm(visita: v)
          : null,
      onDelete: canEdit ? () => _confirmDelete(v) : null,
      users: context.read<UserListProvider>().users,
    );

    return Positioned(
      top: top,
      // Divide column width among overlapping slots
      left: hPad + slotIndex * (1 / totalSlots * 100),
      right: hPad + (totalSlots - 1 - slotIndex) * (1 / totalSlots * 100),
      height: height,
      child: canEdit
          ? Draggable<TicketVisita>(
              data: v,
              feedback: Material(
                color: Colors.transparent,
                child: Opacity(
                  opacity: 0.85,
                  child: SizedBox(
                    width: 160,
                    height: height,
                    child: card,
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.25, child: card),
              child: card,
            )
          : card,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════ //
// Visit Card                                                                   //
// ════════════════════════════════════════════════════════════════════════════ //

class _VisitCard extends StatelessWidget {
  final TicketVisita visita;
  final Color color;
  final double height;
  final String? titleOverride;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final List<Usuario> users;

  const _VisitCard({
    required this.visita,
    required this.color,
    required this.height,
    required this.users,
    this.titleOverride,
    this.onTap,
    this.onDelete,
  });

  String _techName() {
    try {
      return users
          .firstWhere((u) => u.idPersonal == visita.idPersonalAsignado)
          .nombre;
    } catch (_) {
      return 'Téc. #${visita.idPersonalAsignado}';
    }
  }

  String _timeRange() {
    final fmt = DateFormat('HH:mm');
    return '${fmt.format(visita.fechaInicio)} – ${fmt.format(visita.fechaFin)}';
  }

  @override
  Widget build(BuildContext context) {
    final compact = height < 40;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: compact
            ? Text(
                titleOverride?.isNotEmpty == true
                    ? '${titleOverride!} ${_timeRange()}'
                    : 'Caso #${visita.idCaso}  ${_timeRange()}',
                style: TextStyle(
                    fontSize: 10,
                    color: color.darken(0.3),
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titleOverride?.isNotEmpty == true
                              ? titleOverride!
                              : 'Caso #${visita.idCaso}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: color.darken(0.35)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onDelete != null)
                        GestureDetector(
                          onTap: onDelete,
                          child: Icon(Icons.close,
                              size: 12, color: color.darken(0.2)),
                        ),
                    ],
                  ),
                  Text(
                    _timeRange(),
                    style: TextStyle(
                        fontSize: 10, color: color.darken(0.3)),
                  ),
                  if (height >= 60)
                    Text(
                      _techName(),
                      style: TextStyle(
                          fontSize: 10, color: color.darken(0.2)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (height >= 80 &&
                      visita.descripcion != null &&
                      visita.descripcion!.isNotEmpty)
                    Text(
                      visita.descripcion!,
                      style: TextStyle(
                          fontSize: 9,
                          color: color.darken(0.15),
                          fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════ //
// Grid line painter                                                            //
// ════════════════════════════════════════════════════════════════════════════ //

class _GridLinePainter extends CustomPainter {
  final double hourHeight;
  final int startHour;
  final int endHour;
  final Color? todayBackground;
  final Color? highlightBackground;

  _GridLinePainter({
    required this.hourHeight,
    required this.startHour,
    required this.endHour,
    this.todayBackground,
    this.highlightBackground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Background fill
    if (highlightBackground != null) {
      canvas.drawRect(
          Offset.zero & size, Paint()..color = highlightBackground!);
    } else if (todayBackground != null) {
      canvas.drawRect(
          Offset.zero & size, Paint()..color = todayBackground!);
    }

    // Right border
    final borderPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(size.width - 0.5, 0),
        Offset(size.width - 0.5, size.height),
        borderPaint);

    // Horizontal hour lines
    final hourPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..strokeWidth = 1;
    final halfPaint = Paint()
      ..color = const Color(0xFFF0F0F0)
      ..strokeWidth = 0.5;

    for (int h = startHour; h <= endHour; h++) {
      final y = (h - startHour) * hourHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hourPaint);
      if (h < endHour) {
        final yHalf = y + hourHeight / 2;
        canvas.drawLine(
            Offset(0, yHalf), Offset(size.width, yHalf), halfPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridLinePainter old) =>
      old.todayBackground != todayBackground ||
      old.highlightBackground != highlightBackground;
}

// ════════════════════════════════════════════════════════════════════════════ //
// Extension: Color.darken                                                      //
// ════════════════════════════════════════════════════════════════════════════ //

extension _ColorDarken on Color {
  Color darken(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}

// ════════════════════════════════════════════════════════════════════════════ //
// Visita Form Dialog                                                           //
// ════════════════════════════════════════════════════════════════════════════ //

class _VisitaFormDialog extends StatefulWidget {
  final TicketVisita? visita;
  final DateTime? initialDate;
  /// When set, the case field is pre-filled and locked (used from case detail).
  final int? lockedCaseId;
  final void Function(Map<String, dynamic>) onSaved;

  const _VisitaFormDialog({
    this.visita,
    this.initialDate,
    this.lockedCaseId,
    required this.onSaved,
  });

  @override
  State<_VisitaFormDialog> createState() => _VisitaFormDialogState();
}

class _VisitaFormDialogState extends State<_VisitaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descCtrl;
  late DateTime _fechaInicio;
  late DateTime _fechaFin;
  int? _idPersonalAsignado;
  String _estadoVisita = 'pendiente';
  bool _isSaving = false;

  // Case picker state
  int? _selectedCaseId;
  String? _selectedCaseTitle;

  // Ticket info snippet
  String? _ticketTitulo;
  String? _ticketCliente;
  bool _loadingTicketInfo = false;

  @override
  void initState() {
    super.initState();
    final v = widget.visita;
    final base = widget.initialDate ?? v?.fechaInicio ?? DateTime.now();

    _descCtrl = TextEditingController(text: v?.descripcion ?? '');
    _fechaInicio = v?.fechaInicio ?? base;
    _fechaFin = v?.fechaFin ?? base.add(const Duration(hours: 1));
    _estadoVisita = v?.estadoVisita ?? 'pendiente';

    // Pre-fill case: locked from detail screen takes priority
    if (widget.lockedCaseId != null) {
      _selectedCaseId = widget.lockedCaseId;
      _selectedCaseTitle = 'Caso #${widget.lockedCaseId}';
    } else if (v?.idCaso != null) {
      _selectedCaseId = v!.idCaso;
      _selectedCaseTitle = 'Caso #${v.idCaso}';
    }

    final currentUser = context.read<UserProvider>().user;
    if (currentUser?.idTipo == 1) {
      _idPersonalAsignado = currentUser!.idPersonal;
    } else {
      _idPersonalAsignado = v?.idPersonalAsignado;
    }

    // Fetch ticket info for pre-filled case
    if (_selectedCaseId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _fetchTicketInfo(_selectedCaseId!));
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _openCasePicker() async {
    final apiService = context.read<ApiService>();
    final result = await showDialog<Ticket>(
      context: context,
      builder: (ctx) => _CaseSearchDialog(apiService: apiService),
    );
    if (result != null) {
      setState(() {
        _selectedCaseId = result.idCaso;
        _selectedCaseTitle = '#${result.idCaso} – ${result.titulo}';
        // Populate snippet directly from picker result if client is available
        _ticketTitulo = result.titulo;
        _ticketCliente = result.cliente?.razonSocial;
      });
      // If the picker result didn't include client data, fetch it
      if (result.cliente == null && result.idCaso != null) {
        _fetchTicketInfo(result.idCaso!);
      }
    }
  }

  Future<void> _fetchTicketInfo(int caseId) async {
    if (!mounted) return;
    setState(() => _loadingTicketInfo = true);
    try {
      final apiService = context.read<ApiService>();
      final data = await apiService.getTicketById(caseId.toString());
      final ticket = Ticket.fromJson(data);
      if (mounted) {
        setState(() {
          _ticketTitulo = ticket.titulo;
          _ticketCliente = ticket.cliente?.razonSocial;
          // Also update the display title with the real title
          if (_selectedCaseTitle == 'Caso #$caseId') {
            _selectedCaseTitle = '#$caseId – ${ticket.titulo}';
          }
        });
      }
    } catch (e) {
      // silently ignore — snippet just won't show
    } finally {
      if (mounted) setState(() => _loadingTicketInfo = false);
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initial = isStart ? _fechaInicio : _fechaFin;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null || !mounted) return;
    final result = DateTime(
        date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _fechaInicio = result;
        if (!_fechaFin.isAfter(_fechaInicio)) {
          _fechaFin = result.add(const Duration(hours: 1));
        }
      } else {
        _fechaFin = result;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Seleccione un caso'),
          backgroundColor: kErrorColor));
      return;
    }
    if (_idPersonalAsignado == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Seleccione un técnico'),
          backgroundColor: kErrorColor));
      return;
    }
    if (!_fechaFin.isAfter(_fechaInicio)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('La fecha fin debe ser posterior al inicio'),
          backgroundColor: kErrorColor));
      return;
    }
    
    // Overlapping validation
    final provider = context.read<VisitaProvider>();
    final isOverlap = provider.visitas.any((v) {
      if (v.idVisita == widget.visita?.idVisita) return false;
      if (v.idPersonalAsignado != _idPersonalAsignado) return false;
      return _fechaInicio.isBefore(v.fechaFin) && _fechaFin.isAfter(v.fechaInicio);
    });
    
    if (isOverlap) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('El técnico ya tiene otra visita en ese horario.'),
          backgroundColor: kErrorColor));
      return;
    }

    setState(() => _isSaving = true);
    widget.onSaved({
      'id_caso': _selectedCaseId!,
      'id_personal_asignado': _idPersonalAsignado,
      'fecha_inicio': _fechaInicio.toIso8601String(),
      'fecha_fin': _fechaFin.toIso8601String(),
      'estado_visita': _estadoVisita,
      if (_descCtrl.text.trim().isNotEmpty)
        'descripcion': _descCtrl.text.trim(),
    });
  }

  Widget _dateTile(String label, DateTime dt, bool isStart) {
    return InkWell(
      onTap: () => _pickDateTime(isStart),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(dt),
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<UserProvider>().user;
    final isTecnico = currentUser?.idTipo == 1;
    final users = context.watch<UserListProvider>().users;
    final isEditing = widget.visita != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Visita' : 'Nueva Visita',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caso selector
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: widget.lockedCaseId != null
                          ? // Read-only when coming from case detail screen
                            InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Caso vinculado',
                                prefixIcon: const Icon(Icons.confirmation_number_outlined),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                fillColor: Colors.grey.shade50,
                                filled: true,
                              ),
                              child: Text(
                                _selectedCaseTitle ?? 'Caso #${widget.lockedCaseId}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            )
                          : // Tappable picker
                            GestureDetector(
                              onTap: widget.visita != null ? null : _openCasePicker,
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Caso *',
                                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                                  suffixIcon: widget.visita != null
                                      ? null
                                      : const Icon(Icons.search, size: 18),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  errorText: _selectedCaseId == null && _isSaving
                                      ? 'Seleccione un caso'
                                      : null,
                                  fillColor: widget.visita != null
                                      ? Colors.grey.shade50
                                      : null,
                                  filled: widget.visita != null,
                                ),
                                child: Text(
                                  _selectedCaseTitle ?? 'Toque para buscar un caso...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _selectedCaseTitle == null
                                        ? Colors.grey.shade500
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    if (_selectedCaseId != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          tooltip: 'Ver detalle del caso',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CaseDetailScreen(
                                  caseId: _selectedCaseId!.toString(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
                // ── Ticket info snippet ────────────────────────────
                if (_loadingTicketInfo)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: LinearProgressIndicator(),
                  )
                else if (_ticketTitulo != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: kPrimaryColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16,
                            color: kPrimaryColor.withOpacity(0.7)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _ticketTitulo!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: kPrimaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              if (_ticketCliente != null) ...
                                [
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.person_outline,
                                          size: 12,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        _ticketCliente!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Técnico
                if (isTecnico)
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Técnico asignado',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      fillColor: Colors.grey.shade50,
                      filled: true,
                    ),
                    child: Text(currentUser?.nombre ?? '',
                        style: const TextStyle(fontSize: 14)),
                  )
                else
                  DropdownButtonFormField<int>(
                    value: _idPersonalAsignado,
                    decoration: InputDecoration(
                      labelText: 'Técnico asignado *',
                      prefixIcon:
                          const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: users
                        .map((u) => DropdownMenuItem(
                              value: u.idPersonal,
                              child: Text(u.nombre),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _idPersonalAsignado = v),
                    validator: (v) => v == null
                        ? 'Seleccione un técnico'
                        : null,
                  ),
                const SizedBox(height: 12),

                // Date pickers
                Row(
                  children: [
                    Expanded(
                        child: _dateTile(
                            'Inicio *', _fechaInicio, true)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _dateTile(
                            'Fin *', _fechaFin, false)),
                  ],
                ),
                const SizedBox(height: 12),

                // Estado
                DropdownButtonFormField<String>(
                  value: _estadoVisita,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    prefixIcon:
                        const Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _estadoLabels.entries
                      .map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Row(children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin:
                                    const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _estadoColors[e.key],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(e.value),
                            ]),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _estadoVisita = v!),
                ),
                const SizedBox(height: 12),

                // Descripción
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed:
              _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white),
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(isEditing ? 'Actualizar' : 'Crear'),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════ //
// Public wrapper so case_detail_content can open the form locked to a case ID //
// ════════════════════════════════════════════════════════════════════════════ //

class VisitaFormFromCaseDetail extends StatelessWidget {
  final int? caseId;
  final void Function(Map<String, dynamic>) onSaved;

  const VisitaFormFromCaseDetail({
    super.key,
    required this.caseId,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return _VisitaFormDialog(
      lockedCaseId: caseId,
      onSaved: onSaved,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════ //
// Case Search Dialog                                                           //
// ════════════════════════════════════════════════════════════════════════════ //

class _CaseSearchDialog extends StatefulWidget {
  final ApiService apiService;
  const _CaseSearchDialog({required this.apiService});

  @override
  State<_CaseSearchDialog> createState() => _CaseSearchDialogState();
}

class _CaseSearchDialogState extends State<_CaseSearchDialog> {
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Ticket> _allTickets = [];
  List<Ticket> _filtered = [];

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    try {
      // Fetch pending (1) and in-progress (2) tickets in parallel
      final results = await Future.wait([
        widget.apiService.getTicketsByEstado(1),
        widget.apiService.getTicketsByEstado(2),
      ]);
      final tickets = [
        ...results[0].map((d) => Ticket.fromJson(d as Map<String, dynamic>)),
        ...results[1].map((d) => Ticket.fromJson(d as Map<String, dynamic>)),
      ];
      tickets.sort((a, b) => (b.idCaso ?? 0).compareTo(a.idCaso ?? 0));
      if (mounted) {
        setState(() {
          _allTickets = tickets;
          _filtered = tickets;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar casos: $e';
          _loading = false;
        });
      }
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = _allTickets;
      } else {
        _filtered = _allTickets.where((t) {
          final idStr = t.idCaso?.toString() ?? '';
          return t.titulo.toLowerCase().contains(query) ||
              idStr.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Buscar Caso',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          children: [
            // Search box
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar por título o #ID…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            // Results list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(_error!,
                              style: const TextStyle(color: Colors.red)))
                      : _filtered.isEmpty
                          ? const Center(
                              child: Text('Sin resultados',
                                  style: TextStyle(color: Colors.grey)))
                          : ListView.separated(
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final t = _filtered[i];
                                final isPending = t.idEstado == 1;
                                return ListTile(
                                  dense: true,
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPending
                                          ? Colors.orange.shade50
                                          : kPrimaryColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isPending
                                            ? Colors.orange.shade300
                                            : kPrimaryColor
                                                .withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      '#${t.idCaso}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isPending
                                            ? Colors.orange.shade700
                                            : kPrimaryColor,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    t.titulo,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    isPending ? 'Pendiente' : 'En Proceso',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isPending
                                          ? Colors.orange.shade600
                                          : kPrimaryColor,
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(ctx, t),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
