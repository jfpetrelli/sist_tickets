class ApiConfig {
  // static const String baseUrl = 'http://192.168.0.157:8080'; // Para dispositivo físico

  //static const String baseUrl = 'http://10.0.2.2:8000'; // Para emulador Android
  static const String baseUrl =
      'http://localhost:8000'; // Para web o desarrollo local
  //static const String baseUrl = 'http://10.0.2.2:8000'; // Para emulador Android

  //static const String baseUrl = 'http://192.168.1.6:8000'; // Para emulador iOS
  // Auth endpoints
  static const String login = '$baseUrl/jwt/login';
  static const String register = '$baseUrl/usuarios';
  static const String refresh = '$baseUrl/jwt/refresh';
  static const String me = '$baseUrl/jwt/users/me';

  // Tickets endpoints
  static const String tickets = '$baseUrl/tickets/';
  static const String ticketById = '$baseUrl/tickets/';
  static const String ticketIntervenciones = '$baseUrl/ticket_intervencion/';

  // User endpoints
  static const String users = '$baseUrl/usuarios';
  static const String userById = '$baseUrl/usuarios/'; // Agregar ID al final

  // Client endpoints
  static const String clients = '$baseUrl/clientes/';

  static const String tiposCaso = '$baseUrl/tipos_caso/';

  // Document endpoints
  static const String adjuntosByTicket =
      '$baseUrl/adjuntos/ticket/'; // Agregar ID del ticket al final
  static const String downloadAdjunto =
      '$baseUrl/adjuntos/'; // Agregar ID del adjunto al final
}
