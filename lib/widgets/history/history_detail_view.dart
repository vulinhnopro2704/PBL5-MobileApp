import 'package:flutter/material.dart';
import 'package:mobile_v2/config/app_theme.dart';
import 'package:mobile_v2/models/history_item.dart';

import 'components/detection_image_view.dart';
import 'components/detection_list_view.dart';
import 'components/history_header_view.dart';

class HistoryDetailView extends StatelessWidget {
  final HistoryItem item;

  const HistoryDetailView({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Draggable handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header with description and timestamp
              HistoryHeaderView(item: item),

              const SizedBox(height: 24),

              // Detection image with bounding boxes
              if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                DetectionImageView(
                  imageUrl: item.imageUrl,
                  detectionData: item.detectionData,
                ),

              const SizedBox(height: 24),

              // Detection data list
              DetectionListView(detectionData: item.detectionData),

              const SizedBox(height: 32),

              // Close button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }
}
