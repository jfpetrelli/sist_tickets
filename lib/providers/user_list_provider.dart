// lib/providers/user_list_provider.dart

import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../api/api_service.dart';

class UserListProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Usuario> _users = [];
  bool isLoading = false;
  String? errorMessage;

  List<Usuario> get users => _users;

  UserListProvider(this._apiService);

  Future<void> fetchUsers({required int userType}) async {
    isLoading = true;
    notifyListeners();
    try {
      // 👇 --- INICIO DE LA MODIFICACIÓN ---
      debugPrint("🔄 Buscando usuarios con tipo: $userType");
      final responseData = await _apiService.getUsers(userType: userType);

      debugPrint("✅ Respuesta de la API recibida: $responseData");
      _users = responseData.map((data) => Usuario.fromJson(data)).toList();

      errorMessage = null;
    } catch (e) {
      // 👇 --- INICIO DE LA MODIFICACIÓN ---
      debugPrint("❌ Error en fetchUsers: $e");
      // --- FIN DE LA MODIFICACIÓN ---
      errorMessage = 'No se pudieron cargar los usuarios.';
      _users = [];
    }
    isLoading = false;
    notifyListeners();
  }
}
