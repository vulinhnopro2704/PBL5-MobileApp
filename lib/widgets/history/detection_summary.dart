import 'package:flutter/material.dart';
import 'utils.dart';

class DetectionSummary extends StatelessWidget {
  final Map<String, dynamic> detectionData;

  const DetectionSummary({super.key, required this.detectionData});

  @override
  Widget build(BuildContext context) {
    if (!detectionData.containsKey('objects') ||
        detectionData['objects'] is! List ||
        (detectionData['objects'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    final objects = List<Map<String, dynamic>>.from(detectionData['objects']);
    final objectCounts = <String, int>{};

    // Count objects by class
    for (final obj in objects) {
      final className = obj['class_name'] ?? 'Unknown';
      objectCounts[className] = (objectCounts[className] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected ${objects.length} object${objects.length > 1 ? 's' : ''}:',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                objectCounts.entries.map((entry) {
                  return Chip(
                    backgroundColor: HistoryUtils.getClassColor(
                      entry.key,
                    ).withOpacity(0.8),
                    label: Text(
                      '${entry.key} (${entry.value})',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    avatar: Icon(
                      HistoryUtils.getClassIcon(entry.key),
                      color: Colors.white,
                      size: 16,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }
}

class DetailedDetectionResults extends StatelessWidget {
  final Map<String, dynamic> detectionData;

  const DetailedDetectionResults({super.key, required this.detectionData});

  @override
  Widget build(BuildContext context) {
    if (!detectionData.containsKey('objects') ||
        detectionData['objects'] is! List ||
        (detectionData['objects'] as List).isEmpty) {
      return const Text(
        'No objects detected',
        style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
      );
    }

    final objects = List<Map<String, dynamic>>.from(detectionData['objects']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary text
        Text(
          'Detected ${objects.length} object${objects.length > 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),

        // List of detected objects
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: objects.length,
          separatorBuilder:
              (context, index) =>
                  const Divider(color: Colors.white12, height: 16),
          itemBuilder: (context, index) {
            final obj = objects[index];
            final className = obj['class_name'] ?? 'Unknown';
            final confidence = obj['confidence'] ?? 0.0;

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: HistoryUtils.getClassColor(
                      className,
                    ).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    HistoryUtils.getClassIcon(className),
                    color: HistoryUtils.getClassColor(className),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (obj.containsKey('location'))
                        Text(
                          'Location: ${obj['location']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: HistoryUtils.getConfidenceColor(confidence),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
