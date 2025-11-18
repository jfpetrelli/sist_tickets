// lib/providers/ticket_provider.dart

import 'package:flutter/foundation.dart';
import '../models/ticket.dart';
import '../models/intervencion_ticket.dart';
import '../models/calificacion_ticket.dart';
import '../models/usuario.dart';
import '../api/api_service.dart';

class TicketProvider extends ChangeNotifier {
  // Método para guardar una nueva intervención en un ticket
  Future<bool> addIntervencion(
      int ticketId, TicketIntervencion intervencion) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.addIntervencion(ticketId, intervencion.toJson());
      // Actualiza el ticket localmente
      await getTicketById(ticketId.toString());
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error en addIntervencion: $e');
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  final ApiService _apiService;

  List<Ticket> _tickets = [];
  Ticket? _ticket;
  CalificacionTicket? _calificacion;
  bool isLoading = false;

  List<Ticket> get tickets => _tickets;
  Ticket? get ticket => _ticket;

  // El constructor ahora requiere una instancia de ApiService
  TicketProvider(this._apiService);

  Future<void> fetchTickets(Usuario? currentUser) async {
    isLoading = true;
    notifyListeners();
    try {
      String? idPersonalAsignado;
      // Solo enviar el id del usuario si es tipo 1 (técnico)
      if (currentUser != null && currentUser.idTipo == 1) {
        idPersonalAsignado = currentUser.idPersonal.toString();
      }
      // Si es tipo 2 (administrador), no envía parámetro para obtener todos los tickets

      final responseData = await _apiService.getTickets(idPersonalAsignado);
      _tickets = responseData.map((data) => Ticket.fromJson(data)).toList();
    } catch (e) {
      print('Error en fetchTickets: $e');
      _tickets = []; // En caso de error, devuelve una lista vacía
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> getTicketById(String id) async {
    isLoading = true;
    notifyListeners();
    try {
      final responseData = await _apiService.getTicketById(id);
      _ticket = Ticket.fromJson(responseData);
    } catch (e) {
      print('Error en getTicketById: $e');
      _ticket = null;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> updateTicket(String id, Ticket ticket) async {
    isLoading = true;
    notifyListeners();
    try {
      await _apiService.updateTicket(id, ticket.toJson());

      // Actualiza el ticket en la lista local para no tener que recargar todo
      final index = _tickets.indexWhere((t) => t.idCaso.toString() == id);
      if (index != -1) {
        // Obtenemos los datos actualizados para refrescar la UI localmente
        await getTicketById(id);
        _tickets[index] = _ticket!;
      }

      isLoading = false;
      notifyListeners();
      return true; // Indica que la operación fue exitosa
    } catch (e) {
      print('Error en updateTicket (provider): $e');
      isLoading = false;
      notifyListeners();
      return false; // Indica que hubo un error
    }
  }

  CalificacionTicket? get calificacion => _calificacion;
  Future<void> getCalificacionByTicketId(String id) async {
    isLoading = true;
    notifyListeners();
    try {
      final responseData = await _apiService.getCalificacionByTicketId(id);
      // Aquí puedes manejar la calificación obtenida según tus necesidades
      _calificacion = CalificacionTicket.fromJson(responseData);
      print('Calificación obtenida: ${_calificacion?.puntuacion}');
    } catch (e) {
      print('Error en getCalificacionByTicketId: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
    isLoading = false;
    notifyListeners();
  }
}
