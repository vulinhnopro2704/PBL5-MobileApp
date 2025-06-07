import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/history_item.dart';
import '../models/firebase_models.dart';
import 'log_service.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'detections';
  final int _pageSize = 20;

  // Fetch initial history batch from Firestore
  Future<List<HistoryItem>> getHistory() async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .orderBy('timestamp', descending: true)
              .limit(_pageSize)
              .get();

      return _processQuerySnapshot(querySnapshot);
    } catch (e) {
      LogService.error('Error fetching history from Firestore', e);
      return [];
    }
  }

  // Fetch next page of history items
  Future<List<HistoryItem>> getNextPage(HistoryItem lastItem) async {
    try {
      final querySnapshot =
          await _firestore
              .collection(_collection)
              .orderBy('timestamp', descending: true)
              .startAfter([
                Timestamp.fromMillisecondsSinceEpoch(
                  lastItem.timestamp.millisecondsSinceEpoch,
                ),
              ])
              .limit(_pageSize)
              .get();

      return _processQuerySnapshot(querySnapshot);
    } catch (e) {
      LogService.error('Error fetching next history page', e);
      return [];
    }
  }

  // Process Firestore query snapshot into history items
  List<HistoryItem> _processQuerySnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      try {
        // Convert to our strongly-typed Firebase model
        final firebaseItem = FirebaseHistoryItem.fromDoc(doc);
        LogService.info('Processing history item: ${doc.id}');

        // Log the structured data for debugging
        LogService.debug(
          'Processed Firebase item',
          'ID: ${firebaseItem.id}, Detections: ${firebaseItem.detections.length}',
        );

        // Convert to app's HistoryItem model
        return _convertToHistoryItem(firebaseItem);
      } catch (e, stackTrace) {
        LogService.error(
          'Error processing history document: ${doc.id}',
          e,
          stackTrace,
        );
        // Return an empty history item if processing fails
        return HistoryItem(
          id: doc.id,
          timestamp: DateTime.now(),
          eventType: HistoryEventType.objectDetected,
          imageUrl: '',
          description: 'Error processing data',
          success: false,
        );
      }
    }).toList();
  }

  // Convert Firebase model to app's HistoryItem model
  HistoryItem _convertToHistoryItem(FirebaseHistoryItem item) {
    // Log raw detection data for debugging
    LogService.debug(
      'Converting Firebase detections to app format',
      'Count: ${item.detections.length}, Sample: ${item.detections.isNotEmpty ? item.detections.first.toMap() : "none"}',
    );

    // Prepare detection data in the format expected by the app
    final detectionData = <String, dynamic>{
      'objects':
          item.detections.map((detection) {
            final map = detection.toMap();
            LogService.debug('Mapped detection', 'Bbox: ${map['bbox']}');
            return map;
          }).toList(),
    };

    return HistoryItem(
      id: item.id,
      timestamp: item.timestamp,
      eventType: HistoryEventType.objectDetected,
      imageUrl: item.imageUrl,
      detectionData: detectionData,
      description: _generateDescription(item.detections),
      success: item.detections.isNotEmpty,
    );
  }

  // Generate a description based on detected objects
  String _generateDescription(List<FirebaseDetection> detections) {
    if (detections.isEmpty) {
      return 'No objects detected';
    }

    // Count occurrences of each class
    final Map<String, int> classCount = {};
    for (final detection in detections) {
      final className = detection.className;
      classCount[className] = (classCount[className] ?? 0) + 1;
    }

    // Build description string
    final StringBuffer description = StringBuffer('Detected: ');
    bool isFirst = true;

    classCount.forEach((className, count) {
      if (!isFirst) description.write(', ');
      description.write('$count $className');
      isFirst = false;
    });

    return description.toString();
  }

  // Clear history is not supported with Firestore in this implementation
  Future<bool> clearHistory() async {
    LogService.warning('Clearing Firestore history is not implemented');
    return false;
  }
}
