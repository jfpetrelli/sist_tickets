// lib/api/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sist_tickets/models/usuario.dart';
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

  Future<void> refreshToken() async {
    if (_token == null) {
      throw Exception('No hay token para refrescar.');
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.refresh),
        headers: {
          'Authorization': 'Bearer $_token'
        }, // Enviamos el token para el refresh
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setToken(data['access_token']);
      } else {
        clearToken();
        throw Exception('Sesión expirada.');
      }
    } catch (e) {
      clearToken();
      rethrow;
    }
  }

  Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function() request,
  ) async {
    var response = await request();
    if (response.statusCode == 401) {
      try {
        await refreshToken(); // Intenta refrescar el token
        response =
            await request(); // Reintenta la solicitud original con el nuevo token
      } catch (e) {
        // Si el refresh falla, propaga la excepción para que la UI pueda reaccionar
        // (por ejemplo, redirigiendo al login).
        rethrow;
      }
    }
    return response;
  }

  Future<Usuario> getMe() async {
    final response = await _makeAuthenticatedRequest(
      () => http.get(Uri.parse(ApiConfig.me), headers: _headers),
    );

    if (response.statusCode == 200) {
      return Usuario.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falló al cargar los datos del usuario');
    }
  }

  void logout() {
    clearToken();
  }

  Future<List<dynamic>> getTickets() async {
    final response = await _makeAuthenticatedRequest(
        () => http.get(Uri.parse(ApiConfig.tickets), headers: _headers));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Error al obtener tickets: ${response.statusCode}, ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getTicketById(String id) async {
    final response = await _makeAuthenticatedRequest(() => http.get(
        Uri.parse('${ApiConfig.ticketById}$id')
            .replace(queryParameters: {'incluir_cliente': 'true'}),
        headers: _headers));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener ticket por ID: ${response.statusCode}');
    }
  }
}
