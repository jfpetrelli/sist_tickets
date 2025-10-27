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

  // Calcular los límites (bounds) de la firma
  Rect _calculateBounds() {
    if (_points.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final point in _points) {
      if (point != Offset.zero) {
        minX = minX < point.dx ? minX : point.dx;
        minY = minY < point.dy ? minY : point.dy;
        maxX = maxX > point.dx ? maxX : point.dx;
        maxY = maxY > point.dy ? maxY : point.dy;
      }
    }

    // Añadir padding alrededor de la firma
    const padding = 20.0;
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  Future<String> exportImageBytes() async {
    if (_points.isEmpty) return '';

    // Calcular los límites de la firma
    final bounds = _calculateBounds();
    if (bounds.width <= 0 || bounds.height <= 0) return '';

    // Crear un canvas para dibujar
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Rellenar el fondo con blanco
    canvas.drawRect(
      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      Paint()..color = Colors.white,
    );

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Ajustar los puntos al nuevo origen (bounds)
    List<Offset> segmentPoints = [];
    for (int i = 0; i < _points.length; i++) {
      if (_points[i] == Offset.zero) {
        // Es un separador, dibujar el segmento actual
        for (int j = 0; j < segmentPoints.length - 1; j++) {
          canvas.drawLine(segmentPoints[j], segmentPoints[j + 1], paint);
        }
        segmentPoints.clear();
      } else {
        // Ajustar el punto restando el offset de los bounds
        final adjustedPoint = Offset(
          _points[i].dx - bounds.left,
          _points[i].dy - bounds.top,
        );
        segmentPoints.add(adjustedPoint);
      }
    }

    // Dibujar el último segmento
    if (segmentPoints.length > 1) {
      for (int j = 0; j < segmentPoints.length - 1; j++) {
        canvas.drawLine(segmentPoints[j], segmentPoints[j + 1], paint);
      }
    }

    // Convertir a imagen con el tamaño exacto de los bounds
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      bounds.width.toInt(),
      bounds.height.toInt(),
    );
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
          border: Border.all(color: Colors.grey[300]!, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            size: Size.infinite,
            painter: _SignaturePainter(_points),
          ),
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
