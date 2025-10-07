// lib/providers/client_provider.dart

import 'package:flutter/foundation.dart';
import '../models/cliente.dart';
import '../api/api_service.dart';

class ClientProvider extends ChangeNotifier {
  Future<void> addClient(Cliente nuevoCliente) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.createClient(nuevoCliente.toJson());
      final clienteCreado = Cliente.fromJson(response);
      _clients.add(clienteCreado);
      errorMessage = null;
    } catch (e) {
      errorMessage = 'No se pudo agregar el cliente.';
    }
    isLoading = false;
    notifyListeners();
  }

  final ApiService _apiService;

  List<Cliente> _clients = [];
  bool isLoading = false;
  String? errorMessage;

  List<Cliente> get clients => _clients;

  ClientProvider(this._apiService);

  Future<void> fetchClients() async {
    isLoading = true;
    notifyListeners();
    try {
      final responseData = await _apiService.getClients();
      _clients = responseData.map((data) => Cliente.fromJson(data)).toList();
      errorMessage = null;
    } catch (e) {
      print('Error en fetchClients: $e');
      errorMessage = 'No se pudieron cargar los clientes.';
      _clients = [];
    }
    isLoading = false;
    notifyListeners();
  }
}
