import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_theme.dart';
import 'object_detection_painter.dart';

class CameraPanel extends StatelessWidget {
  final String? imageUrl;
  final bool isCameraLoading;
  final bool isDetecting;
  final List<Map<String, dynamic>> detectedObjects;
  final VoidCallback onCapture;
  final VoidCallback onDetect;
  final VoidCallback onClose;

  const CameraPanel({
    super.key,
    this.imageUrl,
    required this.isCameraLoading,
    required this.isDetecting,
    required this.detectedObjects,
    required this.onCapture,
    required this.onDetect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title with close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.camera, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Camera & AI', style: AppTheme.subheadingStyle),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: onClose,
                iconSize: 20,
                splashRadius: 20,
              ),
            ],
          ),
          const Divider(color: Colors.white24),

          // Make the rest of the content scrollable
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image display area
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          isCameraLoading
                              ? const Center(child: CircularProgressIndicator())
                              : imageUrl != null
                              ? Stack(
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      placeholder:
                                          (context, url) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                      errorWidget:
                                          (context, url, error) => const Center(
                                            child: Icon(
                                              Icons.error,
                                              color: Colors.red,
                                              size: 50,
                                            ),
                                          ),
                                    ),
                                  ),

                                  // Object detection boxes
                                  if (detectedObjects.isNotEmpty)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: ObjectDetectionPainter(
                                          objects: detectedObjects,
                                        ),
                                      ),
                                    ),

                                  // Loading overlay when detecting
                                  if (isDetecting)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black54,
                                        child: const Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 16),
                                              Text(
                                                'Detecting objects...',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              )
                              : const Center(
                                child: Text(
                                  'No image captured',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Camera control buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isCameraLoading ? null : onCapture,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            isCameraLoading ? 'Capturing...' : 'Capture Image',
                            style: AppTheme.buttonTextStyle,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed:
                              isDetecting || imageUrl == null ? null : onDetect,
                          icon: const Icon(Icons.search),
                          label: Text(
                            isDetecting ? 'Detecting...' : 'Detect Objects',
                            style: AppTheme.buttonTextStyle,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Display detection results
                  if (detectedObjects.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    DetectionResultsChips(detectedObjects: detectedObjects),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DetectionResultsChips extends StatelessWidget {
  final List<Map<String, dynamic>> detectedObjects;

  const DetectionResultsChips({super.key, required this.detectedObjects});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          detectedObjects.map((obj) {
            final String label = obj['class'] ?? 'Unknown';
            final double confidence = obj['confidence'] ?? 0.0;
            final Color chipColor = _getClassColor(label);

            return Chip(
              label: Text(
                '$label (${(confidence * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: chipColor,
              avatar: Icon(_getClassIcon(label), color: Colors.white, size: 16),
            );
          }).toList(),
    );
  }

  // Helper method to get an appropriate icon for each object class
  IconData _getClassIcon(String className) {
    switch (className.toLowerCase()) {
      case 'person':
        return Icons.person;
      case 'car':
      case 'truck':
      case 'bus':
        return Icons.directions_car;
      case 'bottle':
      case 'cup':
        return Icons.local_drink;
      case 'trash':
      case 'garbage':
        return Icons.delete;
      default:
        return Icons.category;
    }
  }

  // Helper method to get a color for each object class
  Color _getClassColor(String className) {
    switch (className.toLowerCase()) {
      case 'person':
        return Colors.blue;
      case 'car':
      case 'truck':
      case 'bus':
        return Colors.green;
      case 'bottle':
      case 'cup':
        return Colors.orange;
      case 'trash':
      case 'garbage':
        return Colors.red;
      default:
        return Colors.purple;
    }
  }
}
