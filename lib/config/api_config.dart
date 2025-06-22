class ApiConfig {
  // static const String baseUrl = 'http://192.168.0.157:8080'; // Para dispositivo físico
  static const String baseUrl = 'http://10.0.2.2:8000'; // Para emulador Android
  // static const String baseUrl = 'http://localhost:8000'; // Para web o desarrollo local

  // Auth endpoints
  static const String login = '$baseUrl/jwt/login';
  static const String register = '$baseUrl/usuarios';

  // Tickets endpoints
  static const String tickets = '$baseUrl/tickets';
  static const String ticketById = '$baseUrl/tickets/'; // Agregar ID al final

  // User endpoints
  static const String users = '$baseUrl/usuarios';
  static const String userById = '$baseUrl/usuarios/'; // Agregar ID al final
}
