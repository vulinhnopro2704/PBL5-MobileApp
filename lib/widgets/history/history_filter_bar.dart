import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/history_item.dart';

class HistoryFilterBar extends StatelessWidget {
  final HistoryEventType? filterType;
  final String searchQuery;
  final int filteredCount;
  final int totalCount;
  final VoidCallback onClearFilters;

  const HistoryFilterBar({
    super.key,
    required this.filterType,
    required this.searchQuery,
    required this.filteredCount,
    required this.totalCount,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    if (filterType == null && searchQuery.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppTheme.surfaceDark.withOpacity(0.7),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            'Filtered results: $filteredCount of $totalCount',
            style: const TextStyle(color: Colors.white70),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Clear'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.accentColor,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
