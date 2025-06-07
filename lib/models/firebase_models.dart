import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a single detection from Firebase
class FirebaseDetection {
  final List<double> bbox;
  final double confidence;
  final int classId;
  final String className;

  FirebaseDetection({
    required this.bbox,
    required this.confidence,
    required this.classId,
    required this.className,
  });

  /// Create a FirebaseDetection from a Map (JSON)
  factory FirebaseDetection.fromMap(Map<String, dynamic> map) {
    // Convert bbox to List<double> from any numeric list
    List<double> normalizeBbox(dynamic bboxData) {
      if (bboxData is List) {
        return bboxData
            .map<double>((value) => (value as num).toDouble())
            .toList();
      }
      return [0.0, 0.0, 0.0, 0.0]; // Default if bbox is invalid
    }

    return FirebaseDetection(
      bbox: normalizeBbox(map['bbox']),
      confidence:
          map['confidence'] is num
              ? (map['confidence'] as num).toDouble()
              : 0.0,
      classId: map['class_id'] is int ? map['class_id'] : 0,
      className: map['class_name']?.toString() ?? 'Unknown',
    );
  }

  /// Convert to a Map for storage or transmission
  Map<String, dynamic> toMap() {
    return {
      'bbox': bbox,
      'confidence': confidence,
      'class_id': classId,
      'class_name': className,
    };
  }
}

/// Model representing a history item from Firebase
class FirebaseHistoryItem {
  final String id;
  final String imageUrl;
  final String timeString;
  final List<FirebaseDetection> detections;
  final DateTime timestamp;

  FirebaseHistoryItem({
    required this.id,
    required this.imageUrl,
    required this.timeString,
    required this.detections,
    required this.timestamp,
  });

  /// Create a FirebaseHistoryItem from a Firestore document
  factory FirebaseHistoryItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse detections
    List<FirebaseDetection> parseDetections(dynamic detectionsData) {
      if (detectionsData is List) {
        return detectionsData
            .whereType<Map<String, dynamic>>()
            .map(
              (detection) =>
                  FirebaseDetection.fromMap(detection),
            )
            .toList();
      }
      return [];
    }

    // Parse timestamp
    DateTime parseTimestamp(dynamic timestampData) {
      if (timestampData is Timestamp) {
        return timestampData.toDate();
      }
      return DateTime.now();
    }

    return FirebaseHistoryItem(
      id: doc.id,
      imageUrl: data['image_url'] ?? '',
      timeString: data['time_string'] ?? '',
      detections: parseDetections(data['detections']),
      timestamp: parseTimestamp(data['timestamp']),
    );
  }
}
