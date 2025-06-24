// lib/api/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiService {
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Login ahora usa setToken internamente
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          setToken(
              data['access_token']); // Establece el token al iniciar sesión
        }
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error en el inicio de sesión');
      }
    } catch (e) {
      throw Exception('Error en el inicio de sesión: $e');
    }
  }

  // Logout ahora usa clearToken
  void logout() {
    clearToken();
  }

  // Los siguientes métodos ya no son estáticos
  Future<List<dynamic>> getTickets() async {
    final response =
        await http.get(Uri.parse(ApiConfig.tickets), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Error al obtener tickets: ${response.statusCode}, ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getTicketById(String id) async {
    final response = await http.get(Uri.parse('${ApiConfig.ticketById}$id'),
        headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener ticket por ID: ${response.statusCode}');
    }
  }

  // ... (el resto de los métodos: create, update, delete, etc. también sin 'static')
}
