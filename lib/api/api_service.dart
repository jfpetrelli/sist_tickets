// lib/api/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sist_tickets/models/usuario.dart';
import 'api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  String? _token;
  final _storage = const FlutterSecureStorage();

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  void setToken(String token) {
    _token = token;
    _storage.write(key: 'access_token', value: token);
  }

  // Modifica el login para que espere ambos tokens y los guarde
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['access_token'] != null && data['refresh_token'] != null) {
        setToken(data['access_token']);
        await _storage.write(
            key: 'refresh_token', value: data['refresh_token']);
      }
      if (kDebugMode) {
        // Esto asegura que el código solo se ejecute en modo debug
        final storedAccessToken = await _storage.read(key: 'access_token');
        final storedRefreshToken = await _storage.read(key: 'refresh_token');
        debugPrint('--- VERIFICACIÓN DE TOKENS EN STORAGE ---');
        debugPrint('✅ Access Token guardado: $storedAccessToken');
        debugPrint('🔑 Refresh Token guardado: $storedRefreshToken');
        debugPrint('-----------------------------------------');
      }
      return data;
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error en el inicio de sesión');
    }
  }

  void clearToken() {
    _token = null;
    _storage.delete(key: 'access_token');
    _storage.delete(key: 'refresh_token');
  }

  void logout() {
    clearToken();
  }

  Future<bool> tryLoadToken() async {
    final storedToken = await _storage.read(key: 'access_token');
    if (storedToken != null) {
      _token = storedToken;
      return true;
    }
    return false;
  }

  // Modifica refreshToken para que envíe el token en el cuerpo
  Future<void> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (refreshToken == null) {
      throw Exception('No hay token de refresh para renovar la sesión.');
    }

    final response = await http.post(
      Uri.parse(ApiConfig.refresh),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'refresh_token': refreshToken}), // Envía el token en el body
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setToken(data['access_token']);
    } else {
      clearToken();
      throw Exception('Sesión expirada.');
    }
  }

  Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function() request,
  ) async {
    var response = await request();
    if (response.statusCode == 401) {
      try {
        await refreshToken();
        response = await request();
      } catch (e) {
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

  Future<List<dynamic>> getClients() async {
    final response = await _makeAuthenticatedRequest(
      // Asumimos que la ruta es /clientes/
      () => http.get(Uri.parse(ApiConfig.clients), headers: _headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener clientes: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getUsers({int? userType}) async {
    var uri = Uri.parse(ApiConfig.users);
    if (userType != null) {
      uri = uri.replace(queryParameters: {'id_tipo': userType.toString()});
    }

    final response = await _makeAuthenticatedRequest(
      () => http.get(uri, headers: _headers),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener usuarios');
    }
  }

  Future<Map<String, dynamic>> createTicket(
      Map<String, dynamic> ticketData) async {
    final response = await _makeAuthenticatedRequest(
      () => http.post(
        Uri.parse(ApiConfig.tickets), // Usamos la URL base de tickets
        headers: _headers,
        body: jsonEncode(ticketData),
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // 201 Created es también un éxito
      return jsonDecode(response.body);
    } else {
      print('Error al crear el ticket: ${response.body}');
      throw Exception('Error al crear el ticket: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateTicket(
      String id, Map<String, dynamic> ticketData) async {
    final response = await _makeAuthenticatedRequest(
      () => http.put(
        Uri.parse('${ApiConfig.tickets}$id'),
        headers: _headers,
        body: jsonEncode(ticketData),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error al actualizar el ticket: ${response.body}');
      throw Exception('Error al actualizar el ticket: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getAdjuntosByTicket(String ticketId) async {
    print('Fetching adjuntos for ticket ID: $ticketId');
    final response = await _makeAuthenticatedRequest(
      () => http.get(
        Uri.parse('${ApiConfig.adjuntosByTicket}$ticketId'),
        headers: _headers,
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Error al obtener adjuntos del ticket: ${response.statusCode}');
    }
  }
}
