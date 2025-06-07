import 'package:flutter/material.dart';

class ObjectDetectionPainter extends CustomPainter {
  final List<Map<String, dynamic>> objects;

  ObjectDetectionPainter({required this.objects});

  @override
  void paint(Canvas canvas, Size size) {
    for (var obj in objects) {
      // Get bounding box coordinates (normalized from 0 to 1)
      final List<dynamic> boxData = obj['bbox'] ?? [0, 0, 0, 0];
      final double x = boxData[0] * size.width;
      final double y = boxData[1] * size.height;
      final double w = boxData[2] * size.width;
      final double h = boxData[3] * size.height;

      final String label = obj['class'] ?? 'Unknown';
      final double confidence = obj['confidence'] ?? 0.0;

      // Create rectangle
      final rect = Rect.fromLTWH(x, y, w, h);

      // Create paint for the box
      final paint =
          Paint()
            ..color = _getBoxColor(label)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

      // Draw box
      canvas.drawRect(rect, paint);

      // Draw label background
      final textPaint = Paint()..color = _getBoxColor(label);

      canvas.drawRect(Rect.fromLTWH(x, y - 20, w, 20), textPaint);

      // Draw label text
      final textSpan = TextSpan(
        text: ' $label ${(confidence * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(minWidth: 0, maxWidth: w);
      textPainter.paint(canvas, Offset(x, y - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  Color _getBoxColor(String className) {
    switch (className.toLowerCase()) {
      case 'glass':
        return Colors.blue;
      case 'metal':
        return Colors.green;
      case 'plastic':
        return Colors.orange;
      case 'paper':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }
}
