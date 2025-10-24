// lib/providers/user_list_provider.dart

import 'package:flutter/foundation.dart';
import '../models/usuario.dart';
import '../api/api_service.dart';

class UserListProvider extends ChangeNotifier {
  
  Future<void> addUserWithPassword(
      Usuario nuevoUsuario, String password) async {
    isLoading = true;
    notifyListeners();
    try {
      final data = _usuarioToJson(nuevoUsuario);
      data.remove('id_personal');
      data['password'] = password;
      print(data);
      final response = await _apiService.createUser(data);
      final usuarioCreado = Usuario.fromJson(response);
      _users.add(usuarioCreado);
      errorMessage = null;
    } catch (e) {
      print('Error en addUserWithPassword: $e');
      errorMessage = 'No se pudo agregar el usuario.';
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> addUser(Usuario nuevoUsuario) async {
    isLoading = true;
    notifyListeners();
    try {
      final response =
          await _apiService.createUser(_usuarioToJson(nuevoUsuario));
      final usuarioCreado = Usuario.fromJson(response);
      _users.add(usuarioCreado);
      errorMessage = null;
    } catch (e) {
      print('Error en addUser: $e');
      errorMessage = 'No se pudo agregar el usuario.';
    }
    isLoading = false;
    notifyListeners();
  }

  Map<String, dynamic> _usuarioToJson(Usuario usuario) {
    return {
      'id_personal': usuario.idPersonal,
      'id_sucursal': usuario.idSucursal,
      'id_tipo': usuario.idTipo,
      'nombre': usuario.nombre,
      'telefono_movil': usuario.telefonoMovil,
      'email': usuario.email,
      'fecha_ingreso': usuario.fechaIngreso?.toIso8601String(),
      'fecha_egreso': usuario.fechaEgreso?.toIso8601String(),
    };
  }

  final ApiService _apiService;

  List<Usuario> _users = [];
  bool isLoading = false;
  String? errorMessage;

  List<Usuario> get users => _users;

  UserListProvider(this._apiService);

  Future<void> fetchUsers({int? userType}) async {
    isLoading = true;
    notifyListeners();
    try {
      final responseData = await _apiService.getUsers(userType: userType);
      _users = responseData.map((data) => Usuario.fromJson(data)).toList();
      errorMessage = null;
    } catch (e) {
      debugPrint("Error en fetchUsers: $e");
      errorMessage = 'No se pudieron cargar los usuarios.';
      _users = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<bool> updateUser(Usuario usuarioActualizado) async {
    isLoading = true;
    notifyListeners();
    try {
      final userData = usuarioActualizado.toJson();

      // Llamar al método de ApiService que agregamos
      await _apiService.updateUser(usuarioActualizado.idPersonal, userData);

      // Actualizar la lista local para reflejar el cambio inmediatamente
      final index = _users.indexWhere((u) => u.idPersonal == usuarioActualizado.idPersonal);
      if (index != -1) {
        _users[index] = usuarioActualizado;
      }
      errorMessage = null;
      isLoading = false;
      notifyListeners();
      return true; // Indicar éxito
    } catch (e) {
      errorMessage = 'No se pudo actualizar el usuario: ${e.toString()}';
      isLoading = false;
      notifyListeners();
      print('Error en updateUser Provider: $e'); // Log para depuración
      return false; // Indicar fallo
    }
  }
}
