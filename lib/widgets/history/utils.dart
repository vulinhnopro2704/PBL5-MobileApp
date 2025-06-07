import 'package:flutter/material.dart';
import '../../models/history_item.dart';

/// Utility class for history-related widgets
class HistoryUtils {
  // Get color based on event type
  static Color getEventColor(HistoryEventType eventType) {
    switch (eventType) {
      case HistoryEventType.imageCaptured:
        return Colors.blue;
      case HistoryEventType.objectDetected:
        return Colors.purple;
      case HistoryEventType.trashGrabbed:
        return Colors.orange;
    }
  }

  // Helper methods for visualization
  static IconData getClassIcon(String className) {
    switch (className.toLowerCase()) {
      case 'person':
        return Icons.person;
      case 'car':
      case 'truck':
      case 'bus':
        return Icons.directions_car;
      case 'bottle':
        return Icons.liquor;
      case 'cup':
        return Icons.coffee;
      case 'chair':
        return Icons.chair;
      case 'trash':
      case 'garbage':
        return Icons.delete;
      default:
        return Icons.widgets;
    }
  }

  static Color getClassColor(String className) {
    // Generate a consistent color based on the class name
    final hashCode = className.hashCode;
    return Color.fromARGB(
      255,
      50 + (hashCode % 200),
      50 + ((hashCode >> 8) % 200),
      50 + ((hashCode >> 16) % 200),
    );
  }

  static Color getConfidenceColor(double confidence) {
    if (confidence < 0.5) {
      return Colors.red;
    } else if (confidence < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Get consistent colors for object classes
  static Map<String, Color> getClassColors(
    List<Map<String, dynamic>> detections,
  ) {
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
      } else if (detection.containsKey('class_name')) {
        classes.add(detection['class_name'].toString());
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
  }
}
