import 'package:flutter/foundation.dart';
import '../models/adjunto.dart';
import '../api/api_service.dart';
import 'package:path_provider/path_provider.dart';

class AdjuntoProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<Adjunto> _adjuntos = [];
  bool isLoading = false;
  String? errorMessage;

  // New state for tracking download progress
  final Map<int, double> _downloadProgress = {};
  Map<int, double> get downloadProgress => _downloadProgress;

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

  // post para subir un adjunto
  Future<void> uploadAdjunto(String ticketId, String filePath) async {
    try {
      await _apiService.uploadAdjunto(ticketId, filePath);
    } catch (e) {
      print('Error al subir el adjunto: $e');
      throw Exception('No se pudo subir el adjunto.');
    }
  }

  Future<void> downloadAdjunto(Adjunto adjunto) async {
    try {
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception('No se pudo obtener el directorio de descargas.');
      }
      final savePath = '${directory.path}/${adjunto.filename}';
      print('Guardando adjunto en: $savePath');

      _downloadProgress[adjunto.idAdjunto] = 0.0;
      notifyListeners();

      await _apiService.downloadAdjunto(
        adjunto.idAdjunto,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _downloadProgress[adjunto.idAdjunto] = received / total;
            print(
                'Progreso de descarga: ${_downloadProgress[adjunto.idAdjunto]}');
            notifyListeners();
          }
        },
      );

      _downloadProgress.remove(adjunto.idAdjunto);
      notifyListeners();

      // You can add logic here to open the file or show a success message.
    } catch (e) {
      _downloadProgress.remove(adjunto.idAdjunto);
      notifyListeners();
      throw Exception('No se pudo descargar el adjunto.');
    }
  }
}
