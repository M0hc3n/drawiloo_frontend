// models/drawing_point.dart
import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({
    required this.offset,
    required this.paint,
  });

  DrawingPoint copyWith({
    Offset? offset,
    Paint? paint,
  }) {
    return DrawingPoint(
      offset: offset ?? this.offset,
      paint: paint ?? this.paint,
    );
  }
}

class DrawingState {
  static Paint defaultPaint = Paint()
    ..color = Colors.black
    ..isAntiAlias = true
    ..strokeWidth = 5.0
    ..strokeCap = StrokeCap.round;

  static Paint createPaint({
    required Color color,
    required double strokeWidth,
  }) {
    return Paint()
      ..color = color
      ..isAntiAlias = true
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
  }
}
