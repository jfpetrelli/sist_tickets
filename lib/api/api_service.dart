// lib/api/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sist_tickets/models/usuario.dart';
import 'api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
//For downloading files.

import 'package:dio/dio.dart';

class ApiService {
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    final response = await _makeAuthenticatedRequest(
      () => http.post(
        Uri.parse(ApiConfig.users),
        headers: _headers,
        body: jsonEncode(userData),
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Error al crear el usuario:${response.body}');
      throw Exception('Error al crear el usuario: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createClient(
      Map<String, dynamic> clientData) async {
    final response = await _makeAuthenticatedRequest(
      () => http.post(
        Uri.parse(ApiConfig.clients),
        headers: _headers,
        body: jsonEncode(clientData),
      ),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Error al crear el cliente: ${response.body}');
      throw Exception('Error al crear el cliente: ${response.statusCode}');
    }
  }

  String? _token;
  final _storage = const FlutterSecureStorage();
  final Dio _dio = Dio();

  // Métodos auxiliares para storage que funcionen en web y móvil
  Future<void> _writeSecurely(String key, String value) async {
    try {
      if (kIsWeb) {
        // En web, usar SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
        debugPrint('✅ Token guardado en SharedPreferences (Web)');
      } else {
        // En móvil, usar FlutterSecureStorage
        await _storage.write(key: key, value: value);
        debugPrint('✅ Token guardado en SecureStorage (Mobile)');
      }
    } catch (e) {
      debugPrint('💥 Error al guardar en storage: $e');
      rethrow;
    }
  }

  Future<String?> _readSecurely(String key) async {
    try {
      if (kIsWeb) {
        // En web, usar SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final value = prefs.getString(key);
        debugPrint(
            '📦 Token leído de SharedPreferences (Web): ${value != null ? "Encontrado" : "No encontrado"}');
        return value;
      } else {
        // En móvil, usar FlutterSecureStorage
        final value = await _storage.read(key: key);
        debugPrint(
            '📦 Token leído de SecureStorage (Mobile): ${value != null ? "Encontrado" : "No encontrado"}');
        return value;
      }
    } catch (e) {
      debugPrint('💥 Error al leer de storage: $e');
      return null;
    }
  }

  Future<void> _deleteSecurely(String key) async {
    try {
      if (kIsWeb) {
        // En web, usar SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(key);
        debugPrint('🗑️ Token eliminado de SharedPreferences (Web)');
      } else {
        // En móvil, usar FlutterSecureStorage
        await _storage.delete(key: key);
        debugPrint('🗑️ Token eliminado de SecureStorage (Mobile)');
      }
    } catch (e) {
      debugPrint('💥 Error al eliminar de storage: $e');
    }
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  void setToken(String token) async {
    try {
      debugPrint('💾 Guardando token en storage...');
      _token = token;
      await _writeSecurely('access_token', token);
      debugPrint('✅ Token guardado exitosamente');
    } catch (e) {
      debugPrint('💥 Error al guardar token: $e');
      // Aunque falle el storage, mantenemos el token en memoria
      _token = token;
    }
  }

  // Modifica el login para que espere ambos tokens y los guarde
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('🚀 Iniciando login request a: ${ApiConfig.login}');
      debugPrint('📝 Headers: application/x-www-form-urlencoded');
      debugPrint('👤 Usuario: $email');

      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📄 Response body: ${response.body}');
      debugPrint('🔗 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null && data['refresh_token'] != null) {
          setToken(data['access_token']);
          await _writeSecurely('refresh_token', data['refresh_token']);
        }
        if (kDebugMode) {
          // Esto asegura que el código solo se ejecute en modo debug
          final storedAccessToken = await _readSecurely('access_token');
          final storedRefreshToken = await _readSecurely('refresh_token');
          debugPrint('--- VERIFICACIÓN DE TOKENS EN STORAGE ---');
          debugPrint('Access Token guardado: $storedAccessToken');
          debugPrint('Refresh Token guardado: $storedRefreshToken');
          debugPrint('-----------------------------------------');
        }
        return data;
      } else {
        debugPrint('❌ Login falló con código: ${response.statusCode}');
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error en el inicio de sesión');
      }
    } catch (e) {
      debugPrint('💥 Excepción durante login: $e');
      rethrow;
    }
  }

  void clearToken() async {
    try {
      debugPrint('🗑️ Limpiando tokens...');
      _token = null;
      await _deleteSecurely('access_token');
      await _deleteSecurely('refresh_token');
      debugPrint('✅ Tokens limpiados exitosamente');
    } catch (e) {
      debugPrint('💥 Error al limpiar tokens: $e');
      // Aunque falle el storage, limpiamos el token en memoria
      _token = null;
    }
  }

  void logout() {
    clearToken();
  }

  Future<bool> tryLoadToken() async {
    try {
      debugPrint('🔑 Intentando cargar token desde storage...');
      final storedToken = await _readSecurely('access_token');
      debugPrint('📦 Token encontrado: ${storedToken != null ? "Sí" : "No"}');
      if (storedToken != null) {
        _token = storedToken;
        debugPrint('✅ Token cargado exitosamente');
        return true;
      }
      debugPrint('❌ No hay token guardado');
      return false;
    } catch (e) {
      debugPrint('💥 Error al cargar token desde storage: $e');
      return false;
    }
  }

  // Modifica refreshToken para que envíe el token en el cuerpo
  Future<void> refreshToken() async {
    try {
      debugPrint('🔄 Intentando renovar token...');
      final refreshToken = await _readSecurely('refresh_token');

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
        debugPrint('✅ Token renovado exitosamente');
      } else {
        clearToken();
        throw Exception('Sesión expirada.');
      }
    } catch (e) {
      debugPrint('💥 Error al renovar token: $e');
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

  Future<List<dynamic>> getTickets([String? idPersonalAsignado]) async {
    Uri uri;
    if (idPersonalAsignado != null) {
      uri = Uri.parse(
          '${ApiConfig.tickets}?id_personal_asignado=$idPersonalAsignado');
    } else {
      uri = Uri.parse(ApiConfig.tickets);
    }

    final response =
        await _makeAuthenticatedRequest(() => http.get(uri, headers: _headers));

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
      print('Response body: ${response.body}');
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener ticket por ID: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getTiposCaso() async {
    final response = await _makeAuthenticatedRequest(
      () => http.get(Uri.parse(ApiConfig.tiposCaso), headers: _headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener tipos de caso: ${response.statusCode}');
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

  //post para subir un adjunto
  Future<Map<String, dynamic>> uploadAdjunto(
      String ticketId, String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.adjuntosByTicket}$ticketId'),
    );
    request.headers.addAll(_headers);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
      ),
    );
    final response = await request.send();
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = await response.stream.bytesToString();
      return jsonDecode(responseData);
    } else {
      throw Exception(
          'Error al subir el adjunto: ${response.statusCode}, ${response.reasonPhrase}');
    }
  }

  // Método para descargar un adjunto usando DIO Recibe el filepath por parametro
  Future<void> downloadAdjunto(int adjuntoId, String savePath,
      {required Function(int, int) onReceiveProgress}) async {
    try {
      await _dio.download(
        '${ApiConfig.downloadAdjunto}$adjuntoId',
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: _headers,
        ),
      );
    } catch (e) {
      print('Error downloading file: $e');
      throw Exception('Failed to download file.');
    }
  }

  // Guarda una nueva intervención para un ticket
  Future<Map<String, dynamic>> addIntervencion(
      int ticketId, Map<String, dynamic> intervencionData) async {
    final response = await _makeAuthenticatedRequest(
      () => http.post(
        Uri.parse('${ApiConfig.ticketIntervenciones}$ticketId/intervenciones'),
        headers: _headers,
        body: jsonEncode(intervencionData),
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      print('Error al guardar la intervención: [31m${response.body}[0m');
      throw Exception(
          'Error al guardar la intervención: ${response.statusCode}');
    }
  }
}
