import 'package:flutter/foundation.dart';
import '../models/adjunto.dart';
import '../api/api_service.dart';

class AdjuntoProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Adjunto> _adjuntos = [];
  bool isLoading = false;
  String? errorMessage;

  List<Adjunto> get adjuntos => _adjuntos;

  AdjuntoProvider(this._apiService);

  Future<void> fetchAdjuntos(String ticketId) async {
    isLoading = true;
    notifyListeners();
    try {
      final responseData = await _apiService.getAdjuntosByTicket(ticketId);
      _adjuntos = responseData.map((data) => Adjunto.fromJson(data)).toList();
      errorMessage = null;
    } catch (e) {
      print('Error en fetchAdjuntos: $e');
      errorMessage = 'No se pudieron cargar los adjuntos.';
      _adjuntos = [];
    }
    isLoading = false;
    notifyListeners();
  }

/*   Future<void> downloadAdjunto(String adjuntoId) async {
    try {
      await _apiService.downloadAdjunto(adjuntoId);
    } catch (e) {
      print('Error al descargar el adjunto: $e');
      throw Exception('No se pudo descargar el adjunto.');
    }
  } */

  // post para subir un adjunto
  Future<void> uploadAdjunto(String ticketId, String filePath) async {
    try {
      await _apiService.uploadAdjunto(ticketId, filePath);
    } catch (e) {
      print('Error al subir el adjunto: $e');
      throw Exception('No se pudo subir el adjunto.');
    }
  }
}
