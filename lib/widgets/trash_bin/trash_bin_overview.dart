import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/trash_bin_model.dart';

class TrashBinOverview extends StatelessWidget {
  final TrashBinData data;

  const TrashBinOverview({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration.copyWith(
        gradient: AppTheme.primaryGradient,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Trash Bin Status',
                  style: AppTheme.headingStyle.copyWith(fontSize: 20),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Total items
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${data.totalItems} items',
                    style: AppTheme.buttonTextStyle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Status indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(),
                  style: AppTheme.bodyStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (data.totalItems == 0) return Colors.grey;
    if (data.totalItems < 20) return AppTheme.connectedColor;
    if (data.totalItems < 40) return Colors.orange;
    return AppTheme.errorColor;
  }

  String _getStatusText() {
    if (data.totalItems == 0) return 'Empty';
    if (data.totalItems < 20) return 'Low capacity';
    if (data.totalItems < 40) return 'Medium capacity';
    return 'High capacity';
  }
}
