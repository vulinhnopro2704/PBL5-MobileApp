import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_v2/services/log_service.dart';
import 'utils.dart';

class DetectionBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> detections;
  final Map<String, Color> classColors;

  // Original image dimensions based on common detection models
  // We'll use these if we can't determine the actual dimensions
  static const double DEFAULT_IMAGE_WIDTH = 1280.0;
  static const double DEFAULT_IMAGE_HEIGHT = 720.0;

  DetectionBoxPainter({required this.detections, required this.classColors});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) {
      LogService.debug(
        'Invalid canvas size',
        'Width: ${size.width}, Height: ${size.height}',
      );
      return;
    }

    LogService.debug(
      'Painting detection boxes',
      'Canvas size: ${size.width}x${size.height}, Detections count: ${detections.length}',
    );

    // Estimate original image dimensions from the first bbox
    double originalWidth = DEFAULT_IMAGE_WIDTH;
    double originalHeight = DEFAULT_IMAGE_HEIGHT;

    // Try to determine the original image dimensions from the bounding box coordinates
    if (detections.isNotEmpty && detections[0].containsKey('bbox')) {
      final bbox = detections[0]['bbox'];
      if (bbox is List && bbox.length >= 4) {
        // Get the max coordinates as a hint of the original image dimensions
        double maxX = 0, maxY = 0;
        for (var detection in detections) {
          if (detection.containsKey('bbox')) {
            final coords = detection['bbox'] as List;
            maxX = max(maxX, coords[2].toDouble());
            maxY = max(maxY, coords[3].toDouble());
          }
        }
        // If the max coordinates are much larger than our canvas, assume they are in pixel units
        if (maxX > size.width * 2 || maxY > size.height * 2) {
          originalWidth = max(
            maxX * 1.1,
            DEFAULT_IMAGE_WIDTH,
          ); // Add 10% margin
          originalHeight = max(
            maxY * 1.1,
            DEFAULT_IMAGE_HEIGHT,
          ); // Add 10% margin
          LogService.debug(
            'Estimated original image size',
            'Width: $originalWidth, Height: $originalHeight',
          );
        }
      }
    }

    // Calculate scaling factor for the "contain" fit
    double scaleX = size.width / originalWidth;
    double scaleY = size.height / originalHeight;
    double scale = min(
      scaleX,
      scaleY,
    ); // Use the smaller scale to ensure the image fits

    // Calculate image display size
    double displayWidth = originalWidth * scale;
    double displayHeight = originalHeight * scale;

    // Calculate offset to center the image in the container
    double offsetX = (size.width - displayWidth) / 2;
    double offsetY = (size.height - displayHeight) / 2;

    LogService.debug(
      'Image scaling',
      'Scale: $scale, Display size: ${displayWidth}x$displayHeight, Offset: ($offsetX,$offsetY)',
    );

    // Dump first few detections for debugging
    if (detections.isNotEmpty) {
      final sample = detections.take(3).toList();
      LogService.debug('Detection samples', sample.toString());
    }

    int successfullyDrawn = 0;

    for (int i = 0; i < detections.length; i++) {
      final detection = detections[i];
      try {
        // Skip if no bounding box
        if (!detection.containsKey('bbox') || detection['bbox'] == null) {
          LogService.debug(
            'Detection missing bbox',
            'Detection #$i: $detection',
          );
          continue;
        }

        final bbox = detection['bbox'];
        LogService.debug(
          'Raw bbox data',
          'Type: ${bbox.runtimeType}, Value: $bbox',
        );

        // Handle different possible bbox formats
        List<double> coordinates = [];

        if (bbox is List) {
          // Convert all elements to double
          coordinates =
              bbox
                  .map((value) => (value is num) ? value.toDouble() : 0.0)
                  .toList();

          LogService.debug(
            'Bbox coordinates from list',
            'Detection #$i: $coordinates',
          );
        } else if (bbox is Map) {
          // Handle map format with x, y, width, height or similar
          if (bbox.containsKey('x') &&
              bbox.containsKey('y') &&
              bbox.containsKey('width') &&
              bbox.containsKey('height')) {
            final x = (bbox['x'] is num) ? (bbox['x'] as num).toDouble() : 0.0;
            final y = (bbox['y'] is num) ? (bbox['y'] as num).toDouble() : 0.0;
            final w =
                (bbox['width'] is num)
                    ? (bbox['width'] as num).toDouble()
                    : 0.0;
            final h =
                (bbox['height'] is num)
                    ? (bbox['height'] as num).toDouble()
                    : 0.0;
            coordinates = [x, y, x + w, y + h];

            LogService.debug(
              'Bbox coordinates from map',
              'Detection #$i: $coordinates',
            );
          }
        }

        // Skip if we couldn't get valid coordinates
        if (coordinates.length < 4) {
          LogService.debug(
            'Invalid bbox coordinates length',
            'Detection #$i: $coordinates',
          );
          continue;
        }

        // Get class name and confidence
        final className =
            detection['class_name'] as String? ??
            detection['class'] as String? ??
            'Unknown';

        final confidence =
            detection['confidence'] as double? ??
            detection['score'] as double? ??
            0.0;

        // Scale and transform coordinates to fit the display
        final x1 = coordinates[0] * scale + offsetX;
        final y1 = coordinates[1] * scale + offsetY;
        final x2 = coordinates[2] * scale + offsetX;
        final y2 = coordinates[3] * scale + offsetY;

        LogService.debug(
          'Scaled coordinates',
          'Original: [${coordinates[0]},${coordinates[1]},${coordinates[2]},${coordinates[3]}], Scaled: [$x1,$y1,$x2,$y2]',
        );

        // Create a rectangle
        final rect = Rect.fromLTRB(x1, y1, x2, y2);

        // Get color based on class
        final color =
            classColors[className] ?? HistoryUtils.getClassColor(className);

        // Draw rectangle with more visible stroke
        final paint =
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0;

        canvas.drawRect(rect, paint);

        // Draw label background
        final labelText =
            '$className ${(confidence * 100).toStringAsFixed(0)}%';
        final textStyle = const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        );

        final textSpan = TextSpan(text: labelText, style: textStyle);

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();

        // Ensure label stays within canvas bounds
        double labelY = y1 - textPainter.height - 4;
        if (labelY < 0) {
          labelY = y1 + 4; // Move label below if it would go off the top
        }

        final labelRect = Rect.fromLTWH(
          x1,
          labelY,
          textPainter.width + 8,
          textPainter.height + 4,
        );

        final labelPaint = Paint()..color = color.withOpacity(0.8);

        canvas.drawRect(labelRect, labelPaint);

        // Draw label text
        textPainter.paint(canvas, Offset(x1 + 4, labelY + 2));

        successfullyDrawn++;
        LogService.debug(
          'Drew detection box',
          'Detection #$i: Class: $className, Confidence: $confidence, Rect: $rect',
        );
      } catch (e, stackTrace) {
        // Skip this detection if there's an error
        LogService.debug(
          'Error painting detection box',
          'Detection #$i: ${e.toString()}\n$stackTrace',
        );
        continue;
      }
    }

    LogService.debug(
      'Painting summary',
      'Successfully drew $successfullyDrawn/${detections.length} detection boxes',
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
