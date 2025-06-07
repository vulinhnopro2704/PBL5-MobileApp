import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mobile_v2/services/log_service.dart';
import '../detection_box_painter.dart';
import '../utils.dart';

class DetectionImageView extends StatelessWidget {
  final String? imageUrl;
  final Map<String, dynamic>? detectionData;

  const DetectionImageView({
    super.key,
    required this.imageUrl,
    this.detectionData,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // Log the detection data structure
      if (detectionData != null) {
        LogService.debug(
          'Detection data in image view',
          'Keys: ${detectionData!.keys.join(", ")}, Full data: $detectionData',
        );
      }

      if (imageUrl == null) {
        return const Center(
          child: Text(
            'No image available',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      if (detectionData == null || !detectionData!.containsKey('objects')) {
        // If we don't have object detection data, just show the image
        LogService.debug(
          'No objects data found',
          'Available keys: ${detectionData?.keys.join(", ") ?? "none"}',
        );
        return CachedNetworkImage(
          imageUrl: imageUrl!,
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
      final objectsData = detectionData!['objects'];
      LogService.debug(
        'Objects data type',
        'Type: ${objectsData.runtimeType}, Raw data: $objectsData',
      );

      List<Map<String, dynamic>> detections = _parseDetections(objectsData);

      // Check if we have valid bbox data in any detection
      bool hasValidBbox = detections.any(
        (detection) => detection.containsKey('bbox'),
      );

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
                  imageUrl: imageUrl!,
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
                          classColors: HistoryUtils.getClassColors(detections),
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

  List<Map<String, dynamic>> _parseDetections(dynamic objectsData) {
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
      // If objects is neither Map nor List, log it
      LogService.debug(
        'Unexpected objects data type',
        'Type: ${objectsData.runtimeType}, Value: $objectsData',
      );
    }

    return detections;
  }
}
