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

  static Color getConfidenceColor(double confidence) {
    if (confidence < 0.5) {
      return Colors.red;
    } else if (confidence < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
