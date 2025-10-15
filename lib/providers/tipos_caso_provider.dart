import 'package:flutter/foundation.dart';
import '../models/tipo_caso.dart';
import '../api/api_service.dart';

class TiposCasoProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<TipoCaso> _tiposCaso = [];
  bool isLoading = false;
  String? errorMessage;

  List<TipoCaso> get tiposCaso => _tiposCaso;

  TiposCasoProvider(this._apiService);

  Future<void> fetchTiposCaso() async {
    isLoading = true;
    notifyListeners();
    try {
      final responseData = await _apiService.getTiposCaso();
      _tiposCaso = responseData.map((data) => TipoCaso.fromJson(data)).toList();

      errorMessage = null;
    } catch (e) {
      debugPrint("Error en fetchTiposCaso: $e");
      errorMessage = 'No se pudieron cargar los tipos de caso.';
      _tiposCaso = [];
    }
    isLoading = false;
    notifyListeners();
  }
}
