import 'package:sist_tickets/model/ticket.dart';
import 'package:flutter/foundation.dart';

class TicketProvider extends ChangeNotifier {
  List<Ticket> _tickets = [];
  Ticket? _ticket;
  List<Ticket> get tickets => _tickets;
  Ticket? get ticket => _ticket;

  bool isLoading = false;

  Future<void> fetchTickets() async {
    isLoading = true;
    notifyListeners();
    _tickets = await Ticket.getTickets();
    isLoading = false;
    notifyListeners();
  }

  Future<void> getTicketById(String id) async {
    isLoading = true;
    notifyListeners();
    _ticket = await Ticket.getTicketById(id);
    isLoading = false;
    notifyListeners();
  }
}
