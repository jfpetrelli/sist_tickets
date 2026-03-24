// lib/providers/visita_provider.dart

import 'package:flutter/foundation.dart';
import '../models/ticket_visita.dart';
import '../models/usuario.dart';
import '../api/api_service.dart';

class VisitaProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<TicketVisita> _visitas = [];
  bool isLoading = false;
  String? errorMessage;

  List<TicketVisita> get visitas => _visitas;

  VisitaProvider(this._apiService);

  /// Fetch visits for the given explicit date range.
  /// Role filter is applied automatically:
  ///   - TECNICO (idTipo == 1): always filters by their own id_personal
  ///   - ADMIN   (idTipo == 2): no filter (all visits), unless [adminFilterPersonalId] is set
  Future<void> fetchCalendar(
    Usuario? currentUser,
    DateTime fechaInicio,
    DateTime fechaFin, {
    int? adminFilterPersonalId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      int? idPersonalAsignado;

      if (currentUser != null && currentUser.idTipo == 1) {
        // TECNICO — always filter by their own id (cannot be overridden)
        idPersonalAsignado = currentUser.idPersonal;
      } else if (currentUser != null &&
          currentUser.idTipo == 2 &&
          adminFilterPersonalId != null) {
        // ADMIN with manual filter selected
        idPersonalAsignado = adminFilterPersonalId;
      }
      // ADMIN without filter → idPersonalAsignado stays null → returns all

      final responseData = await _apiService.getVisitasCalendar(
        fechaInicio: fechaInicio,
        fechaFin: DateTime(
            fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59),
        idPersonalAsignado: idPersonalAsignado,
      );
      
      final parsedVisits = responseData.map((data) => TicketVisita.fromJson(data)).toList();

      // Fetch case titles to display in the calendar view
      final uniqueCaseIds = parsedVisits.map((v) => v.idCaso).toSet();
      final caseTitles = <int, String>{};
      
      await Future.wait(uniqueCaseIds.map((caseId) async {
        try {
          final ticketData = await _apiService.getTicketById(caseId.toString());
          if (ticketData['titulo'] != null) {
            caseTitles[caseId] = ticketData['titulo'] as String;
          }
        } catch (e) {
          debugPrint('Error fetching title for case $caseId: $e');
        }
      }));

      _visitas = parsedVisits.map((v) {
        if (v.tituloCaso == null && caseTitles.containsKey(v.idCaso)) {
          return v.copyWith(tituloCaso: caseTitles[v.idCaso]);
        }
        return v;
      }).toList();

    } catch (e) {
      debugPrint('Error en VisitaProvider.fetchCalendar: $e');
      errorMessage = 'No se pudieron cargar las visitas.';
      _visitas = [];
    }

    isLoading = false;
    notifyListeners();
  }

  // ------------------------------------------------------------------ //
  // CRUD                                                                 //
  // ------------------------------------------------------------------ //

  Future<bool> createVisita(Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.createVisita(data);
      final nueva = TicketVisita.fromJson(response);
      _visitas.add(nueva);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error en VisitaProvider.createVisita: $e');
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVisita(int visitaId, Map<String, dynamic> data) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.updateVisita(visitaId, data);
      final actualizada = TicketVisita.fromJson(response);
      final idx = _visitas.indexWhere((v) => v.idVisita == visitaId);
      if (idx != -1) {
        _visitas[idx] = actualizada;
      }
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error en VisitaProvider.updateVisita: $e');
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVisita(int visitaId) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.deleteVisita(visitaId);
      _visitas.removeWhere((v) => v.idVisita == visitaId);
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error en VisitaProvider.deleteVisita: $e');
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }
}
