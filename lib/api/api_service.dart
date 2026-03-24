// lib/api/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sist_tickets/models/usuario.dart';
import 'api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';

class ApiService {
  String? getToken() => _token;

  // Cargar el token del storage al inicializar la aplicación
  Future<void> loadToken() async {
    _token = await _readSecurely('access_token');
    debugPrint(
        '📦 Token cargado desde storage: ${_token != null ? "Sí" : "No"}');
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  void setToken(String token) async {
    try {
      debugPrint('Guardando token en storage...');
      _token = token;
      await _writeSecurely('access_token', token);
      debugPrint('✅ Token guardado exitosamente');
    } catch (e) {
      debugPrint('Error al guardar token: $e');
      // Aunque falle el storage, mantenemos el token en memoria
      _token = token;
    }
  }

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
      String mensajeError;
      try {
        // 1. Decodificamos el JSON de error que envía FastAPI
        final errorBody = jsonDecode(response.body);

        // 2. Extraemos el mensaje. FastAPI pone el error en el campo 'detail'.
        // Si 'detail' no existe, usamos un mensaje genérico.
        mensajeError = errorBody['detail'] ?? 'Error al procesar la solicitud';
      } catch (_) {
        // Si el body no es un JSON válido (ej: Error 500 del servidor nginx/apache en HTML)
        mensajeError = 'Error inesperado (${response.statusCode})';
      }

      // 3. Lanzamos la excepción con el mensaje limpio para que el Provider lo capture
      throw Exception(mensajeError);
    }
  }

  Future<Map<String, dynamic>> updateUser(
      int userId, Map<String, dynamic> userData) async {
    final url = Uri.parse('${ApiConfig.users}$userId');
    print('Updating user at: $url');
    print('Data: ${jsonEncode(userData)}');

    final response = await _makeAuthenticatedRequest(
      () => http.put(
        url,
        headers: _headers,
        body: jsonEncode(userData),
      ),
    );

    if (response.statusCode == 200) {
      print('User updated successfully');
      return jsonDecode(response.body);
    } else {
      String mensajeError;
      try {
        final errorBody = jsonDecode(response.body);
        mensajeError = errorBody['detail'] ?? 'Error al actualizar el usuario';
      } catch (_) {
        mensajeError =
            'Error inesperado al actualizar (${response.statusCode})';
      }

      print('Error al actualizar usuario: $mensajeError');
      throw Exception(mensajeError);
    }
  }

  Future<Map<String, dynamic>> userChangePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    final url = Uri.parse('${ApiConfig.users}$userId/change_password');
    print(url);

    print('Changing password for user: $userId');

    final response = await _makeAuthenticatedRequest(
      () => http.put(
        url,
        headers: _headers,
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      ),
    );

    if (response.statusCode == 200) {
      print('Password changed successfully');
      return jsonDecode(response.body);
    } else {
      print(
          'Error al cambiar contraseña: ${response.statusCode} - ${response.body}');
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['detail'] ?? 'Error al cambiar la contraseña');
    }
  }

  // Método para resetear la contraseña de un usuario (solo admin)
  // Backend: PUT /usuarios/{usuario_id}/reset_password (sin body) -> resetea a "1234"
  Future<Map<String, dynamic>> adminResetPassword(int userId) async {
    final url = Uri.parse('${ApiConfig.users}$userId/reset_password');
    print('Admin resetting password for user: $userId');

    final response = await _makeAuthenticatedRequest(
      () => http.put(
        url,
        headers: _headers, // No body: el backend fija la contraseña por defecto
      ),
    );

    if (response.statusCode == 200) {
      print('Password reset successfully');
      return jsonDecode(response.body);
    } else {
      print(
          'Error al resetear contraseña: ${response.statusCode} - ${response.body}');
      try {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['detail'] ?? 'Error al resetear la contraseña');
      } catch (_) {
        throw Exception('Error al resetear la contraseña');
      }
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
      String mensajeError;
      try {
        final bodyError = jsonDecode(response.body);
        // Extraemos el mensaje del campo 'detail'
        mensajeError = bodyError['detail'] ?? 'Error al crear el cliente';
      } catch (_) {
        // Si no es un JSON válido, usamos un mensaje genérico con el código
        mensajeError = 'Error inesperado (${response.statusCode})';
      }

      print('Error al crear el cliente: $mensajeError');
      throw Exception(mensajeError);
    }
  }

  Future<Map<String, dynamic>> updateClient(
      int clientId, Map<String, dynamic> clientData) async {
    final url = Uri.parse('${ApiConfig.clients}$clientId');
    print('Updating client at: $url');
    print('Data: ${jsonEncode(clientData)}');

    final response = await _makeAuthenticatedRequest(
      () => http.put(
        url,
        headers: _headers,
        body: jsonEncode(clientData),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      String mensajeError;
      try {
        // 1. Intentamos leer el JSON del backend
        final bodyError = jsonDecode(response.body);
        // 2. Extraemos el campo 'detail'
        mensajeError = bodyError['detail'] ?? 'Error al actualizar el cliente';
      } catch (_) {
        // Si falla (no es JSON), mensaje genérico con el código
        mensajeError = 'Error inesperado (${response.statusCode})';
      }

      print('Error al actualizar cliente: $mensajeError');
      // 3. Lanzamos la excepción limpia
      throw Exception(mensajeError);
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

  // Modifica el login para que espere ambos tokens y los guarde
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      debugPrint('👤 Usuario: $email');

      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['access_token'] != null && data['refresh_token'] != null) {
          setToken(data['access_token']);
          await _writeSecurely('refresh_token', data['refresh_token']);
        }
        return data;
      } else {
        debugPrint('Login falló con código: ${response.statusCode}');
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Error en el inicio de sesión');
      }
    } catch (e) {
      debugPrint('Excepción durante login: $e');
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
      debugPrint('Error al limpiar tokens: $e');
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

  /// Get tickets filtered by estado (id_estado). Uses the filter endpoint with query param id_estado.
  Future<List<dynamic>> getTicketsByEstado(int estado,
      [String? idPersonalAsignado]) async {
    Uri uri;
    const base = ApiConfig.tickets;
    if (idPersonalAsignado != null) {
      uri = Uri.parse(
          '$base?id_estado=$estado&id_personal_asignado=$idPersonalAsignado');
    } else {
      uri = Uri.parse('$base?id_estado=$estado');
    }

    final response =
        await _makeAuthenticatedRequest(() => http.get(uri, headers: _headers));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Error al obtener tickets por estado: ${response.statusCode}, ${response.body}');
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
        Uri.parse(ApiConfig.ticketById), // Usamos la URL base de tickets
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
        Uri.parse('${ApiConfig.ticketById}$id'),
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

  //post para subir un adjunto - Compatible con Web y Mobile
  Future<Map<String, dynamic>> uploadAdjunto(
      String ticketId, String fileName, List<int> fileBytes) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.adjuntosByTicket}$ticketId'),
    );

    // Asegurar que el token esté cargado
    if (_token == null) {
      _token = await _readSecurely('access_token');
      debugPrint(
          'Token cargado desde storage: ${_token != null ? "Sí" : "No"}');
    }

    // Agregar headers de autenticación sin Content-Type (el navegador lo manejará)
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
      debugPrint('Token presente: ${_token!.substring(0, 20)}...');
    } else {
      debugPrint('⚠️ NO HAY TOKEN DISPONIBLE');
      throw Exception('No hay token de autenticación disponible');
    }

    debugPrint(
        'Subiendo archivo: $fileName (${fileBytes.length} bytes) al ticket $ticketId');

    // Crear MultipartFile desde bytes (funciona tanto en web como mobile)
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ),
    );

    debugPrint('Enviando request a: ${request.url}');
    final response = await request.send();

    debugPrint('Respuesta recibida: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = await response.stream.bytesToString();
      debugPrint('✅ Archivo subido exitosamente');
      return jsonDecode(responseData);
    } else {
      final errorBody = await response.stream.bytesToString();
      debugPrint('❌ Error al subir adjunto: ${response.statusCode}');
      debugPrint('Error response: $errorBody');
      throw Exception(
          'Error al subir el adjunto: ${response.statusCode}, ${response.reasonPhrase}');
    }
  }

  // Método para compatibilidad hacia atrás - NO usar en web
  @Deprecated('Use uploadAdjunto con bytes para compatibilidad web')
  Future<Map<String, dynamic>> uploadAdjuntoFromPath(
      String ticketId, String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError(
          'File path uploads no están soportados en Flutter Web. Use uploadAdjunto con bytes en su lugar.');
    }

    // Este método solo debe usarse desde código que ya maneja la plataforma
    throw UnsupportedError(
        'Este método requiere implementación específica de plataforma.');
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

  // Método para descargar archivos en Flutter Web
  Future<void> downloadAdjuntoWeb(int adjuntoId, String fileName) async {
    if (!kIsWeb) {
      throw UnsupportedError('Este método solo está disponible en Flutter Web');
    }

    try {
      debugPrint('🌐 Iniciando descarga en web: $fileName');

      // Realizar la petición con los headers de autenticación
      final response = await http.get(
        Uri.parse('${ApiConfig.downloadAdjunto}$adjuntoId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        // En Flutter Web, necesitamos crear un blob y descargarlo
        // Por simplicidad, abrimos en nueva ventana para que el usuario descargue
        final downloadUrl = '${ApiConfig.downloadAdjunto}$adjuntoId';

        // Crear URL que incluya el token como query parameter para web
        final token = _token;
        final uriWithAuth = token != null
            ? Uri.parse('$downloadUrl?access_token=$token')
            : Uri.parse(downloadUrl);

        await launchUrl(
          uriWithAuth,
          mode: LaunchMode.externalApplication,
        );

        debugPrint('✅ Descarga iniciada en web');
      } else {
        throw Exception('Error al obtener el archivo: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 Error descargando archivo en web: $e');

      // Como fallback, intentar abrir la URL directamente
      try {
        final downloadUrl = '${ApiConfig.downloadAdjunto}$adjuntoId';
        await launchUrl(
          Uri.parse(downloadUrl),
          mode: LaunchMode.externalApplication,
        );
        debugPrint('📁 Usando descarga fallback');
      } catch (fallbackError) {
        throw Exception('No se pudo descargar el archivo: $e');
      }
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

  Future<Map<String, dynamic>> getTicketStats() async {
    final response = await _makeAuthenticatedRequest(
      () => http.get(Uri.parse(ApiConfig.ticketStats), headers: _headers),
    );

    if (response.statusCode == 200) {
      print(response.body);
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Error al obtener estadísticas de tickets: ${response.statusCode}');
    }
  }

  Future<String> getProfilePhotoUrl(int userId) async {
    final response = await _makeAuthenticatedRequest(
      () => http.get(
        Uri.parse(
            ApiConfig.userProfilePhoto.replaceFirst('{id}', userId.toString())),
        headers: _headers,
      ),
    );

    if (response.statusCode == 200) {
      // Devuelve la URL completa de la imagen
      return ApiConfig.userProfilePhoto.replaceFirst('{id}', userId.toString());
    } else {
      throw Exception('Failed to load profile photo');
    }
  }

  // --- NUEVO MÉTODO PARA SUBIR FOTO ---
  Future<Usuario> uploadProfilePhoto(
      int userId, Uint8List imageBytes, String fileName) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/usuarios/$userId/profile_photo');
    final request = http.MultipartRequest('POST', uri);

    // Adjuntar las cabeceras de autorización
    request.headers.addAll(_headers);

    // Crear el MultipartFile desde los bytes
    final multipartFile = http.MultipartFile.fromBytes(
      'file', // El nombre del campo esperado por el backend FastAPI (UploadFile = File(...))
      imageBytes,
      filename: fileName,
      // Puedes especificar contentType si es necesario, ej: contentType: MediaType('image', 'jpeg')
    );

    // Añadir el archivo a la petición
    request.files.add(multipartFile);

    try {
      // Enviar la petición
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Decodificar la respuesta JSON y convertirla a un objeto Usuario
        final responseData = jsonDecode(response.body);
        return Usuario.fromJson(responseData);
      } else {
        // Manejar errores
        print('Error al subir foto: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Error al subir la foto de perfil: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Excepción al subir foto: $e');
      throw Exception('Error de conexión al subir la foto.');
    }
  }
  // --- FIN NUEVO MÉTODO PARA SUBIR FOTO ---

  // --- NUEVO MÉTODO PARA BORRAR FOTO ---
  Future<Usuario> deleteProfilePhoto(int userId) async {
    final uri =
        Uri.parse('${ApiConfig.baseUrl}/usuarios/$userId/profile_photo');

    // Usar _makeAuthenticatedRequest para manejar posible refresco de token
    final response = await _makeAuthenticatedRequest(
      () => http.delete(
        uri,
        headers: _headers, // _headers ahora NO incluye Content-Type por defecto
      ),
    );

    if (response.statusCode == 200) {
      // Decodificar la respuesta JSON y convertirla a un objeto Usuario
      final responseData = jsonDecode(response.body);
      return Usuario.fromJson(responseData);
    } else {
      // Manejar errores
      print(
          'Error al eliminar foto: ${response.statusCode} - ${response.body}');
      throw Exception(
          'Error al eliminar la foto de perfil: ${response.reasonPhrase}');
    }
  }

  // --- MÉTODOS DE CALIFICACIÓN ---
  Future<Map<String, dynamic>> getCalificacion(String token) async {
    final uri = Uri.parse('${ApiConfig.calificacion}$token');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404 || response.statusCode == 410) {
        throw Exception('invalid_or_used');
      } else {
        throw Exception(
            'Error al obtener calificación: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCalificacionByTicketId(
      String ticketId) async {
    final uri = Uri.parse('${ApiConfig.calificacionTicket}$ticketId');

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404 || response.statusCode == 410) {
        throw Exception('invalid_or_used');
      } else {
        throw Exception(
            'Error al obtener calificación: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitCalificacion(
    String token,
    int estrellas,
    String? comentario,
  ) async {
    final uri = Uri.parse('${ApiConfig.calificacion}$token');

    final body = {
      'puntuacion': estrellas,
      if (comentario != null && comentario.isNotEmpty) 'comentario': comentario,
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error al enviar calificación: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  // --- FIN MÉTODOS DE CALIFICACIÓN ---

  // --- MÉTODOS DE VISITAS ---

  /// GET /visitas/calendar/?fecha_inicio=...&fecha_fin=...&id_personal_asignado=...
  /// Pass [idPersonalAsignado] only for TECNICO users; omit for ADMIN (returns all).
  Future<List<dynamic>> getVisitasCalendar({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    int? idPersonalAsignado,
  }) async {
    final params = <String, String>{
      'fecha_inicio': fechaInicio.toIso8601String(),
      'fecha_fin': fechaFin.toIso8601String(),
      if (idPersonalAsignado != null)
        'id_personal_asignado': idPersonalAsignado.toString(),
    };
    final uri = Uri.parse(ApiConfig.visitasCalendar)
        .replace(queryParameters: params);

    final response = await _makeAuthenticatedRequest(
      () => http.get(uri, headers: _headers),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Error al obtener el calendario de visitas: ${response.statusCode}');
    }
  }

  /// GET /visitas/ticket/{ticket_id}
  Future<List<dynamic>> getVisitasByTicket(int ticketId) async {
    final uri = Uri.parse('${ApiConfig.visitasByTicket}$ticketId');

    final response = await _makeAuthenticatedRequest(
      () => http.get(uri, headers: _headers),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Error al obtener visitas del ticket: ${response.statusCode}');
    }
  }

  /// POST /visitas/
  Future<Map<String, dynamic>> createVisita(
      Map<String, dynamic> visitaData) async {
    final response = await _makeAuthenticatedRequest(
      () => http.post(
        Uri.parse(ApiConfig.visitas),
        headers: _headers,
        body: jsonEncode(visitaData),
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      String mensajeError;
      try {
        final errorBody = jsonDecode(response.body);
        mensajeError = errorBody['detail'] ?? 'Error al crear la visita';
      } catch (_) {
        mensajeError = 'Error inesperado (${response.statusCode})';
      }
      throw Exception(mensajeError);
    }
  }

  /// PUT /visitas/{visita_id}
  Future<Map<String, dynamic>> updateVisita(
      int visitaId, Map<String, dynamic> visitaData) async {
    final uri = Uri.parse('${ApiConfig.visitas}$visitaId');

    final response = await _makeAuthenticatedRequest(
      () => http.put(
        uri,
        headers: _headers,
        body: jsonEncode(visitaData),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      String mensajeError;
      try {
        final errorBody = jsonDecode(response.body);
        mensajeError = errorBody['detail'] ?? 'Error al actualizar la visita';
      } catch (_) {
        mensajeError = 'Error inesperado (${response.statusCode})';
      }
      throw Exception(mensajeError);
    }
  }

  /// DELETE /visitas/{visita_id}
  Future<void> deleteVisita(int visitaId) async {
    final uri = Uri.parse('${ApiConfig.visitas}$visitaId');

    final response = await _makeAuthenticatedRequest(
      () => http.delete(uri, headers: _headers),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      String mensajeError;
      try {
        final errorBody = jsonDecode(response.body);
        mensajeError = errorBody['detail'] ?? 'Error al eliminar la visita';
      } catch (_) {
        mensajeError = 'Error inesperado (${response.statusCode})';
      }
      throw Exception(mensajeError);
    }
  }

  // --- FIN MÉTODOS DE VISITAS ---
}
