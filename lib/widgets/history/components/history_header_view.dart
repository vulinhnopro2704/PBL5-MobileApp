import 'package:flutter/material.dart';
import 'package:mobile_v2/config/app_theme.dart';
import 'package:mobile_v2/models/history_item.dart';
import '../utils.dart';

class HistoryHeaderView extends StatelessWidget {
  final HistoryItem item;

  const HistoryHeaderView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          item.description ?? 'Detection Details',
          style: AppTheme.headingStyle,
        ),

        const SizedBox(height: 8),

        // Timestamp
        Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[400], size: 16),
            const SizedBox(width: 8),
            Text(
              HistoryUtils.formatDateTime(item.timestamp),
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ],
    );
  }
}
