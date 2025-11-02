import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'pdf_downloader_web.dart' if (dart.library.io) 'pdf_downloader_stub.dart';

void downloadPdf(Uint8List bytes, String fileName) {
  if (kIsWeb) {
    downloadPdfWeb(bytes, fileName);
  } else {
    throw UnsupportedError('Para mobile, usa getApplicationDocumentsDirectory');
  }
}
