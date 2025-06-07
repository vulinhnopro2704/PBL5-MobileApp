import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../models/history_item.dart';

class HistoryFilterSheet extends StatefulWidget {
  final HistoryEventType? initialFilterType;
  final String initialSearchQuery;
  final Function(HistoryEventType?, String) onFiltersChanged;

  const HistoryFilterSheet({
    super.key,
    this.initialFilterType,
    required this.initialSearchQuery,
    required this.onFiltersChanged,
  });

  @override
  State<HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<HistoryFilterSheet> {
  late HistoryEventType? _filterType;
  late String _searchQuery;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _filterType = widget.initialFilterType;
    _searchQuery = widget.initialSearchQuery;
    _searchController = TextEditingController(text: _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _filterType = null;
      _searchQuery = '';
      _searchController.text = '';
    });
    widget.onFiltersChanged(null, '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Center(
            child: Text('Filter History', style: AppTheme.subheadingStyle),
          ),
          const SizedBox(height: 24),

          // Event type filter
          const Text(
            'Event Type',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filterType == null,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _filterType = null;
                    });
                    widget.onFiltersChanged(_filterType, _searchQuery);
                  }
                },
                backgroundColor: Colors.white12,
                selectedColor: AppTheme.primaryColor.withOpacity(0.8),
                checkmarkColor: Colors.white,
              ),
              FilterChip(
                label: const Text('Image Capture'),
                selected: _filterType == HistoryEventType.imageCaptured,
                onSelected: (selected) {
                  setState(() {
                    _filterType =
                        selected ? HistoryEventType.imageCaptured : null;
                  });
                  widget.onFiltersChanged(_filterType, _searchQuery);
                },
                backgroundColor: Colors.white12,
                selectedColor: Colors.blue.withOpacity(0.8),
                checkmarkColor: Colors.white,
              ),
              FilterChip(
                label: const Text('Object Detection'),
                selected: _filterType == HistoryEventType.objectDetected,
                onSelected: (selected) {
                  setState(() {
                    _filterType =
                        selected ? HistoryEventType.objectDetected : null;
                  });
                  widget.onFiltersChanged(_filterType, _searchQuery);
                },
                backgroundColor: Colors.white12,
                selectedColor: Colors.purple.withOpacity(0.8),
                checkmarkColor: Colors.white,
              ),
              FilterChip(
                label: const Text('Trash Grabbed'),
                selected: _filterType == HistoryEventType.trashGrabbed,
                onSelected: (selected) {
                  setState(() {
                    _filterType =
                        selected ? HistoryEventType.trashGrabbed : null;
                  });
                  widget.onFiltersChanged(_filterType, _searchQuery);
                },
                backgroundColor: Colors.white12,
                selectedColor: Colors.orange.withOpacity(0.8),
                checkmarkColor: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search filter
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search descriptions...',
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white30),
              ),
              filled: true,
              fillColor: Colors.white10,
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              widget.onFiltersChanged(_filterType, _searchQuery);
            },
          ),
          const SizedBox(height: 24),

          // Apply & Clear buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Clear Filters',
                  style: TextStyle(color: AppTheme.accentColor),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
