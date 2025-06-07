import 'package:flutter/material.dart';
import 'package:mobile_v2/config/app_theme.dart';
import 'package:mobile_v2/services/log_service.dart';
import '../utils.dart';

class DetectionListView extends StatelessWidget {
  final Map<String, dynamic>? detectionData;

  const DetectionListView({super.key, this.detectionData});

  @override
  Widget build(BuildContext context) {
    try {
      if (detectionData == null || !detectionData!.containsKey('objects')) {
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No detection data available',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }

      final objectsData = detectionData!['objects'];

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
      List<dynamic> detectionsList = _convertToList(objectsData);

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
                      color: HistoryUtils.getClassColor(className.toString()),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(className.toString(), style: AppTheme.bodyStyle),
                  subtitle: Text(
                    'Confidence: ${(confidence is double ? confidence * 100 : confidence).toStringAsFixed(1)}%',
                  ),
                  trailing: Icon(
                    HistoryUtils.getClassIcon(className.toString()),
                    color: Colors.grey[400],
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

  List<dynamic> _convertToList(dynamic objectsData) {
    if (objectsData is List) {
      return objectsData;
    } else if (objectsData is Map) {
      return objectsData.values.toList();
    } else {
      LogService.debug(
        'Unexpected detection data format',
        'Type: ${objectsData.runtimeType}',
      );
      return [];
    }
  }
}
