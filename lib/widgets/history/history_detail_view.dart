import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile_v2/config/app_theme.dart';
import 'package:mobile_v2/models/history_item.dart';
import 'package:mobile_v2/services/log_service.dart';

class HistoryDetailView extends StatelessWidget {
  final HistoryItem item;

  const HistoryDetailView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Draggable handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Text(
                item.description ?? 'Detection Details',
                style: AppTheme.headingStyle,
              ),

              const SizedBox(height: 8),

              // Timestamp
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateTime(item.timestamp),
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Detection image with bounding boxes
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                _buildDetectionImage(context),

              const SizedBox(height: 24),

              // Detection data
              _buildDetectionsList(),

              const SizedBox(height: 32),

              // Close button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDetectionImage(BuildContext context) {
    try {
      // Log the detection data structure
      if (item.detectionData != null) {
        LogService.debug(
          'Detection data in detail view',
          'Keys: ${item.detectionData!.keys.join(", ")}, Full data: ${item.detectionData}',
        );
      }

      if (item.imageUrl == null) {
        return const Center(
          child: Text(
            'No image available',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      final detectionData = item.detectionData;
      if (detectionData == null || !detectionData.containsKey('objects')) {
        // If we don't have object detection data, just show the image
        LogService.debug(
          'No objects data found',
          'Available keys: ${detectionData?.keys.join(", ") ?? "none"}',
        );
        return CachedNetworkImage(
          imageUrl: item.imageUrl!,
          fit: BoxFit.contain,
          placeholder:
              (context, url) =>
                  const Center(child: CircularProgressIndicator()),
          errorWidget:
              (context, url, error) => const Center(
                child: Icon(Icons.error_outline, color: Colors.red),
              ),
        );
      }

      // Handle both Map and List structures for 'objects'
      final objectsData = detectionData['objects'];
      LogService.debug(
        'Objects data type',
        'Type: ${objectsData.runtimeType}, Raw data: $objectsData',
      );

      List<Map<String, dynamic>> detections = [];

      if (objectsData is List) {
        // If objects is already a List, use it directly (after ensuring it's the right type)
        detections = List<Map<String, dynamic>>.from(
          objectsData.map(
            (item) =>
                item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{},
          ),
        );
        LogService.debug(
          'Parsed detections from list',
          'Count: ${detections.length}, First item: ${detections.isNotEmpty ? detections.first : "none"}',
        );
      } else if (objectsData is Map) {
        // If objects is a Map, convert it to a List of Maps
        detections =
            objectsData.entries
                .map(
                  (entry) =>
                      entry.value is Map
                          ? Map<String, dynamic>.from(entry.value as Map)
                          : <String, dynamic>{},
                )
                .toList();
        LogService.debug(
          'Parsed detections from map',
          'Count: ${detections.length}, First item: ${detections.isNotEmpty ? detections.first : "none"}',
        );
      } else {
        // If objects is neither Map nor List, log it and show the image without boxes
        LogService.debug(
          'Unexpected objects data type',
          'Type: ${objectsData.runtimeType}, Value: $objectsData',
        );
        return CachedNetworkImage(
          imageUrl: item.imageUrl!,
          fit: BoxFit.contain,
          placeholder:
              (context, url) =>
                  const Center(child: CircularProgressIndicator()),
          errorWidget:
              (context, url, error) => const Center(
                child: Icon(Icons.error_outline, color: Colors.red),
              ),
        );
      }

      // Check if we have valid bbox data in any detection
      bool hasValidBbox = false;
      for (var detection in detections) {
        if (detection.containsKey('bbox')) {
          hasValidBbox = true;
          LogService.debug('Found valid bbox', 'In detection: $detection');
          break;
        }
      }

      if (!hasValidBbox) {
        LogService.debug(
          'No valid bbox found in any detection',
          'Detections: $detections',
        );
      }

      // Add explicit constraints to prevent layout issues
      return Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: Colors.black, // Black background for better visibility
          border: Border.all(color: Colors.grey[700]!, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base image - Center it to match our box calculations
              Center(
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.contain,
                  placeholder:
                      (context, url) =>
                          const Center(child: CircularProgressIndicator()),
                  errorWidget:
                      (context, url, error) => const Center(
                        child: Icon(Icons.error_outline, color: Colors.red),
                      ),
                ),
              ),

              // Detection boxes overlay - only add if detections is not empty
              if (detections.isNotEmpty)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Only render if we have valid constraints
                      if (constraints.maxWidth <= 0 ||
                          constraints.maxHeight <= 0) {
                        LogService.debug(
                          'Invalid constraints',
                          'Width: ${constraints.maxWidth}, Height: ${constraints.maxHeight}',
                        );
                        return const SizedBox();
                      }

                      LogService.debug(
                        'Rendering detection boxes',
                        'Canvas size: ${constraints.maxWidth}x${constraints.maxHeight}, Detections: ${detections.length}',
                      );

                      return CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: DetectionBoxPainter(
                          detections: detections,
                          classColors: _getClassColors(detections),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      LogService.error('Error building detection image', e, stackTrace);
      // Return a fallback widget with error message
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Error displaying detection image: ${e.toString()}',
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
  }

  Widget _buildDetectionsList() {
    try {
      if (item.detectionData == null ||
          !item.detectionData!.containsKey('objects')) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No detection data available',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      final objectsData = item.detectionData!['objects'];

      if (objectsData == null) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Detection data is empty',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      // Convert to list if it's not already
      List<dynamic> detectionsList;
      if (objectsData is List) {
        detectionsList = objectsData;
      } else if (objectsData is Map) {
        detectionsList = objectsData.values.toList();
      } else {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Unexpected detection data format: ${objectsData.runtimeType}',
            style: const TextStyle(color: Colors.white70),
          ),
        );
      }

      if (detectionsList.isEmpty) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No objects detected',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected Objects (${detectionsList.length})',
            style: AppTheme.subheadingStyle,
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: detectionsList.length,
            itemBuilder: (context, index) {
              final detection = detectionsList[index];
              if (detection == null) return const SizedBox.shrink();

              // Handle both possible field names for class
              final className =
                  detection['class_name'] ?? detection['class'] ?? 'Unknown';

              // Handle both possible field names for confidence
              final confidence =
                  detection['confidence'] ?? detection['score'] ?? 0.0;

              return Card(
                color: Colors.grey[850],
                child: ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _getColorForClass(className.toString()),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(className.toString(), style: AppTheme.bodyStyle),
                  subtitle: Text(
                    'Confidence: ${(confidence is double ? confidence * 100 : confidence).toStringAsFixed(1)}%',
                  ),
                ),
              );
            },
          ),
        ],
      );
    } catch (e, stackTrace) {
      LogService.error('Error building detections list', e, stackTrace);
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Error displaying detections: ${e.toString()}',
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }
  }

  Color _getColorForClass(String className) {
    // Generate a consistent color based on the class name
    final hashCode = className.hashCode;
    return Color.fromARGB(
      255,
      50 + (hashCode % 200),
      50 + ((hashCode >> 8) % 200),
      50 + ((hashCode >> 16) % 200),
    );
  }

  // Helper method to get consistent colors for object classes
  Map<String, Color> _getClassColors(List<Map<String, dynamic>> detections) {
    try {
      final classColors = <String, Color>{};
      final predefinedColors = [
        Colors.red,
        Colors.green,
        Colors.blue,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
        Colors.teal,
        Colors.pink,
      ];

      // Collect all unique class names
      final classes = <String>{};
      for (final detection in detections) {
        if (detection.containsKey('class')) {
          classes.add(detection['class'].toString());
        }
      }

      // Assign colors to classes
      int colorIndex = 0;
      for (final className in classes) {
        classColors[className] =
            predefinedColors[colorIndex % predefinedColors.length];
        colorIndex++;
      }

      return classColors;
    } catch (e) {
      LogService.error('Error creating class colors', e);
      return {};
    }
  }
}

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
        final color = classColors[className] ?? _getColorForClass(className);

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

  Color _getColorForClass(String className) {
    // Generate a consistent color based on the class name
    final hashCode = className.hashCode;
    return Color.fromARGB(
      255,
      50 + (hashCode % 200),
      50 + ((hashCode >> 8) % 200),
      50 + ((hashCode >> 16) % 200),
    );
  }
}
