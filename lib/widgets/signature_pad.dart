import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:convert';

class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});

  @override
  SignaturePadState createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  List<Offset> _points = <Offset>[];
  
  void _startPan(Offset point) {
    setState(() {
      // Agregar un punto de inicio (usando Offset.zero como marcador especial)
      _points.add(Offset.zero);
      _points.add(point);
    });
  }

  void _updatePan(Offset point) {
    setState(() {
      _points = List.from(_points)..add(point);
    });
  }

  void _endPan() {
    // Marcar fin del trazo actual agregando un punto de separación
    setState(() {
      _points.add(Offset.zero);
    });
  }

  void clear() {
    setState(() {
      _points.clear();
    });
  }

  Future<String> exportImageBytes() async {
    if (_points.isEmpty) return '';
    
    // Crear un canvas para dibujar
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Dibujar los puntos sin conectar trazos separados
    List<Offset> segmentPoints = [];
    for (int i = 0; i < _points.length; i++) {
      if (_points[i] == Offset.zero) {
        // Es un separador, dibujar el segmento actual
        for (int j = 0; j < segmentPoints.length - 1; j++) {
          canvas.drawLine(segmentPoints[j], segmentPoints[j + 1], paint);
        }
        segmentPoints.clear();
      } else {
        segmentPoints.add(_points[i]);
      }
    }
    
    // Dibujar el último segmento
    if (segmentPoints.length > 1) {
      for (int j = 0; j < segmentPoints.length - 1; j++) {
        canvas.drawLine(segmentPoints[j], segmentPoints[j + 1], paint);
      }
    }

    // Convertir a imagen
    final picture = recorder.endRecording();
    final image = await picture.toImage(800, 400);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();
    
    // Convertir a base64
    return base64Encode(pngBytes);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _startPan(details.localPosition),
      onPanUpdate: (details) => _updatePan(details.localPosition),
      onPanEnd: (details) => _endPan(),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey),
        ),
        child: CustomPaint(
          size: Size.infinite,
          painter: _SignaturePainter(_points),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset> points;

  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Dibujar líneas solo entre puntos consecutivos, saltando los separadores
    List<Offset> segmentPoints = [];
    for (int i = 0; i < points.length; i++) {
      if (points[i] == Offset.zero) {
        // Es un separador, dibujar el segmento actual
        for (int j = 0; j < segmentPoints.length - 1; j++) {
          canvas.drawLine(segmentPoints[j], segmentPoints[j + 1], paint);
        }
        segmentPoints.clear();
      } else {
        segmentPoints.add(points[i]);
      }
    }
    
    // Dibujar el último segmento si quedan puntos sin separador
    if (segmentPoints.length > 1) {
      for (int j = 0; j < segmentPoints.length - 1; j++) {
        canvas.drawLine(segmentPoints[j], segmentPoints[j + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
