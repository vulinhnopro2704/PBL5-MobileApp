import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../config/app_theme.dart';
import '../../models/history_item.dart';
import '../../services/log_service.dart';
import 'detection_summary.dart';
import 'utils.dart';

class HistoryCard extends StatelessWidget {
  final HistoryItem item;
  final Function(HistoryItem) onViewDetails;

  const HistoryCard({
    super.key,
    required this.item,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    // Format timestamp
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final dateString = dateFormat.format(item.timestamp);
    final timeString = timeFormat.format(item.timestamp);

    // Log detection data structure for debugging
    if (item.eventType == HistoryEventType.objectDetected &&
        item.detectionData != null) {
      LogService.debug(
        'HistoryCard: Detection data structure type',
        'Type: ${item.detectionData.runtimeType}, Keys: ${item.detectionData!.keys.join(", ")}',
      );

      // Log the structure of detections key if it exists
      if (item.detectionData!.containsKey('detections')) {
        final detectionsValue = item.detectionData!['detections'];
        LogService.debug(
          'Detections value type and content',
          'Type: ${detectionsValue.runtimeType}, Value: $detectionsValue',
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with event type and timestamp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: HistoryUtils.getEventColor(
                item.eventType,
              ).withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: HistoryUtils.getEventColor(item.eventType),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.eventTypeString,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dateString,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      timeString,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Image if available
          if (item.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.black26,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.black12,
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            size: 32,
                            color: Colors.red,
                          ),
                        ),
                      ),
                ),
              ),
            ),

          // Description
          if (item.description != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                item.description!,
                style: const TextStyle(color: Colors.white),
              ),
            ),

          // Detection results summary (if applicable)
          if (item.eventType == HistoryEventType.objectDetected &&
              item.detectionData != null)
            _buildDetectionSummary(),

          // View details button
          TextButton(
            onPressed: () => _handleViewDetails(context),
            style: TextButton.styleFrom(
              foregroundColor: HistoryUtils.getEventColor(item.eventType),
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  // Safely build detection summary
  Widget _buildDetectionSummary() {
    try {
      // Check if the detection data is valid
      if (item.detectionData == null) {
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'No detection data available',
            style: TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      return DetectionSummary(detectionData: item.detectionData!);
    } catch (e) {
      LogService.error('Error building detection summary in HistoryCard', e);

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Error displaying detection data: ${e.toString()}',
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }
  }

  // Handle view details with error catching
  void _handleViewDetails(BuildContext context) {
    try {
      // Log important data before opening details
      LogService.debug('Opening details for history item:', {
        'id': item.id,
        'eventType': item.eventType.toString(),
        'hasDetectionData': item.detectionData != null,
        'detectionDataType': item.detectionData?.runtimeType,
      });

      onViewDetails(item);
    } catch (e) {
      LogService.error('Failed to open history item details', e);

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
