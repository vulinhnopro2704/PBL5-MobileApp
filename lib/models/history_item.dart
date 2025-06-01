import 'package:flutter/material.dart';

enum HistoryEventType { imageCaptured, objectDetected, trashGrabbed }

class HistoryItem {
  final String id;
  final DateTime timestamp;
  final HistoryEventType eventType;
  final String? imageUrl;
  final Map<String, dynamic>? detectionData;
  final String? description;
  final bool success;

  HistoryItem({
    required this.id,
    required this.timestamp,
    required this.eventType,
    this.imageUrl,
    this.detectionData,
    this.description,
    this.success = true,
  });

  // Create from JSON
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      eventType: _parseEventType(json['event_type'] ?? 'imageCaptured'),
      imageUrl: json['image_url'],
      detectionData: json['detection_data'],
      description: json['description'],
      success: json['success'] ?? true,
    );
  }

  // Helper to parse event type from string
  static HistoryEventType _parseEventType(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'objectdetected':
        return HistoryEventType.objectDetected;
      case 'trashgrabbed':
        return HistoryEventType.trashGrabbed;
      case 'imagecaptured':
      default:
        return HistoryEventType.imageCaptured;
    }
  }

  // Get icon for this event type
  IconData get icon {
    switch (eventType) {
      case HistoryEventType.imageCaptured:
        return Icons.camera_alt;
      case HistoryEventType.objectDetected:
        return Icons.search;
      case HistoryEventType.trashGrabbed:
        return Icons.pan_tool;
    }
  }

  // Get readable event type string
  String get eventTypeString {
    switch (eventType) {
      case HistoryEventType.imageCaptured:
        return 'Image Captured';
      case HistoryEventType.objectDetected:
        return 'Object Detected';
      case HistoryEventType.trashGrabbed:
        return 'Trash Grabbed';
    }
  }
}
