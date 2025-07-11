// lib/providers/ticket_provider.dart

import 'package:flutter/foundation.dart';
import '../models/ticket.dart';
import '../api/api_service.dart';

class TicketProvider extends ChangeNotifier {
  final ApiService _apiService; // Dependencia de ApiService

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
}
