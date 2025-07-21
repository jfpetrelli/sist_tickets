// lib/providers/ticket_provider.dart

import 'package:flutter/foundation.dart';
import '../models/ticket.dart';
import '../api/api_service.dart';

class TicketProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Ticket> _tickets = [];
  Ticket? _ticket;
  bool isLoading = false;

  List<Ticket> get tickets => _tickets;
  Ticket? get ticket => _ticket;

  // El constructor ahora requiere una instancia de ApiService
  TicketProvider(this._apiService);

  Future<void> fetchTickets() async {
    isLoading = true;
    notifyListeners();
    try {
      final responseData = await _apiService.getTickets();
      // La conversión de JSON a Ticket se hace aquí
      print('Response data: $responseData');
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
}
