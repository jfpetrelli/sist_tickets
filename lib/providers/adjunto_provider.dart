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

  // Método principal para subir adjuntos - Compatible con Web y Mobile
  Future<void> uploadAdjuntoFromBytes(
      String ticketId, String fileName, List<int> fileBytes) async {
    try {
      await _apiService.uploadAdjunto(ticketId, fileName, fileBytes);
      // Recargar la lista de adjuntos después de subir
      await fetchAdjuntos(ticketId);
    } catch (e) {
      print('Error al subir el adjunto: $e');
      throw Exception('No se pudo subir el adjunto.');
    }
  }

  // Método legacy para compatibilidad - Solo Mobile
  @Deprecated('Use uploadAdjuntoFromBytes para compatibilidad web')
  Future<void> uploadAdjunto(String ticketId, String filePath) async {
    if (kIsWeb) {
      throw UnsupportedError(
          'File path uploads no están soportados en Flutter Web. Use uploadAdjuntoFromBytes.');
    }

    try {
      // Este método requiere dart:io que no está disponible en web
      throw UnsupportedError('Use uploadAdjuntoFromBytes para subir archivos.');
    } catch (e) {
      print('Error al subir el adjunto: $e');
      throw Exception('No se pudo subir el adjunto.');
    }
  }

  Future<void> downloadAdjunto(Adjunto adjunto) async {
    try {
      _downloadProgress[adjunto.idAdjunto] = 0.0;
      notifyListeners();

      if (kIsWeb) {
        // En Flutter Web, usar descarga del navegador
        await _apiService.downloadAdjuntoWeb(
            adjunto.idAdjunto, adjunto.filename);
      } else {
        // En móvil, usar el método tradicional con path_provider
        final directory = await getDownloadsDirectory();

        if (directory == null) {
          throw Exception('No se pudo obtener el directorio de descargas.');
        }
        final savePath = '${directory.path}/${adjunto.filename}';
        print('Guardando adjunto en: $savePath');

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
      }

      _downloadProgress.remove(adjunto.idAdjunto);
      notifyListeners();

      // You can add logic here to open the file or show a success message.
    } catch (e) {
      _downloadProgress.remove(adjunto.idAdjunto);
      notifyListeners();
      print('Error al descargar adjunto: $e');
      throw Exception('No se pudo descargar el adjunto.');
    }
  }
}
