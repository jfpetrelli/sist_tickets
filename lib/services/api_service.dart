import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  // Login
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null) {
          setToken(data['access_token']);
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

  // Logout
  static void logout() {
    clearToken();
  }

  // Get Tickets
  static Future<List<dynamic>> getTickets() async {
    final response = await http.get(
      Uri.parse(ApiConfig.tickets),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Error al obtener tickets: ${response.statusCode}, ${response.body}');
    }
  }

  // Create Ticket
  static Future<Map<String, dynamic>> createTicket(
      Map<String, dynamic> ticketData) async {
    final response = await http.post(
      Uri.parse(ApiConfig.tickets),
      headers: _headers,
      body: jsonEncode(ticketData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al crear ticket');
    }
  }

  // Update Ticket
  static Future<Map<String, dynamic>> updateTicket(
      String id, Map<String, dynamic> ticketData) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.ticketById}$id'),
      headers: _headers,
      body: jsonEncode(ticketData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al actualizar ticket');
    }
  }

  // Delete Ticket
  static Future<void> deleteTicket(String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.ticketById}$id'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar ticket');
    }
  }

  // Get User Profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await http.get(
      Uri.parse(ApiConfig.users),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener perfil de usuario');
    }
  }
}
