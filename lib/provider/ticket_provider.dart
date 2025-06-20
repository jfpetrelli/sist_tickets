import 'package:sist_tickets/model/ticket.dart';
import 'package:flutter/foundation.dart';

class TicketProvider extends ChangeNotifier {
  List<Ticket> _tickets = [];
  List<Ticket> get tickets => _tickets;
  bool isLoading = false;

  Future<void> fetchTickets() async {
    isLoading = true;
    notifyListeners();
    _tickets = await Ticket.getTickets();
    isLoading = false;
    notifyListeners();
  }
}
