class ApiConfig {
  // static const String baseUrl = 'http://192.168.0.157:8080'; // Para dispositivo físico

  // static const String baseUrl = 'http://10.0.2.2:8000'; // Para emulador Android
  static const String baseUrl =
      'http://localhost:8000'; // Para web o desarrollo local
  //static const String baseUrl = 'http://10.0.2.2:8000'; // Para emulador Android
  //static const String baseUrl = 'http://192.168.1.3:8000'; // Para emulador iOS
  // Auth endpoints
  static const String login = '$baseUrl/jwt/login';
  static const String register = '$baseUrl/usuarios';
  static const String refresh = '$baseUrl/jwt/refresh';
  static const String me = '$baseUrl/jwt/users/me';

  // Tickets endpoints
  static const String tickets = '$baseUrl/tickets/filter/';
  static const String ticketById = '$baseUrl/tickets/';
  static const String ticketIntervenciones = '$baseUrl/ticket_intervencion/';
  static const String ticketStats = '$baseUrl/tickets/stats/all/';

  // User endpoints
  static const String users = '$baseUrl/usuarios/';
  static const String userById = '$baseUrl/usuarios/';
  static const String userProfilePhoto =
      '$baseUrl/usuarios/{userId}/profile_photo';

  // Client endpoints
  static const String clients = '$baseUrl/clientes/';

  static const String tiposCaso = '$baseUrl/tipos_caso/';

  // Document endpoints
  static const String adjuntosByTicket = '$baseUrl/adjuntos/ticket/';
  static const String downloadAdjunto = '$baseUrl/adjuntos/';

  // Calificación endpoints
  static const String calificacion = '$baseUrl/calificacion/';
}
