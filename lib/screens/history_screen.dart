import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../config/app_theme.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../services/log_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<HistoryItem> _historyItems = [];
  bool _isLoading = true;
  String? _error;

  // Filter options
  HistoryEventType? _filterType;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _historyService.getHistory();
      setState(() {
        _historyItems = history;
        _isLoading = false;
      });
    } catch (e) {
      LogService.error('Failed to load history', e);
      setState(() {
        _error = 'Failed to load history: $e';
        _isLoading = false;
      });
    }
  }

  // Filter history items based on current filter settings
  List<HistoryItem> get _filteredHistory {
    return _historyItems.where((item) {
      // Apply type filter if set
      if (_filterType != null && item.eventType != _filterType) {
        return false;
      }

      // Apply search filter if not empty
      if (_searchQuery.isNotEmpty) {
        final description = item.description?.toLowerCase() ?? '';
        return description.contains(_searchQuery.toLowerCase());
      }

      return true;
    }).toList();
  }

  // Clear all history
  Future<void> _clearHistory() async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: AppTheme.surfaceDark,
                title: Text('Clear History', style: AppTheme.subheadingStyle),
                content: Text(
                  'Are you sure you want to clear all history? This action cannot be undone.',
                  style: AppTheme.bodyStyle,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.accentColor),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmed) {
      setState(() {
        _isLoading = true;
      });

      try {
        final success = await _historyService.clearHistory();
        if (success) {
          setState(() {
            _historyItems = [];
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('History cleared successfully')),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to clear history')),
          );
        }
      } catch (e) {
        LogService.error('Error clearing history', e);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Detection History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
          // Clear history button
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _historyItems.isEmpty ? null : _clearHistory,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(child: _buildContent()),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentColor,
        onPressed: _loadHistory,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading history', style: AppTheme.subheadingStyle),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: AppTheme.bodyStyle,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_historyItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 72, color: Colors.white38),
            const SizedBox(height: 16),
            Text('No history yet', style: AppTheme.subheadingStyle),
            const SizedBox(height: 8),
            Text(
              'Your detection and trash collection activities will appear here',
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle,
            ),
          ],
        ),
      );
    }

    final filteredItems = _filteredHistory;

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.filter_list, size: 72, color: Colors.white38),
            const SizedBox(height: 16),
            Text('No results found', style: AppTheme.subheadingStyle),
            const SizedBox(height: 8),
            Text(
              'Try changing your filters or search query',
              textAlign: TextAlign.center,
              style: AppTheme.bodyStyle,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _filterType = null;
                  _searchQuery = '';
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    // If filter is active, show a filter indicator
    Widget? filterIndicator;
    if (_filterType != null || _searchQuery.isNotEmpty) {
      filterIndicator = Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: AppTheme.surfaceDark.withOpacity(0.7),
        child: Row(
          children: [
            const Icon(Icons.filter_list, size: 16, color: Colors.white70),
            const SizedBox(width: 8),
            Text(
              'Filtered results: ${filteredItems.length} of ${_historyItems.length}',
              style: const TextStyle(color: Colors.white70),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _filterType = null;
                  _searchQuery = '';
                });
              },
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

    return Column(
      children: [
        // Show filter indicator if filters are active
        if (filterIndicator != null) filterIndicator,

        // Main history list
        Expanded(
          child: ListView.builder(
            itemCount: filteredItems.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _buildHistoryCard(item);
            },
          ),
        ),
      ],
    );
  }

  // Build history item card
  Widget _buildHistoryCard(HistoryItem item) {
    // Format timestamp
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final dateString = dateFormat.format(item.timestamp);
    final timeString = timeFormat.format(item.timestamp);

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
              color: _getEventColor(item.eventType).withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(item.icon, color: _getEventColor(item.eventType)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.eventTypeString,
                    style: TextStyle(
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
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    Text(
                      timeString,
                      style: TextStyle(fontSize: 12, color: Colors.white70),
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
            _buildDetectionSummary(item.detectionData!),

          // View details button
          TextButton(
            onPressed: () => _showHistoryItemDetails(item),
            style: TextButton.styleFrom(
              foregroundColor: _getEventColor(item.eventType),
            ),
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  // Build detection summary
  Widget _buildDetectionSummary(Map<String, dynamic> detectionData) {
    if (!detectionData.containsKey('objects') ||
        detectionData['objects'] is! List ||
        (detectionData['objects'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    final objects = List<Map<String, dynamic>>.from(detectionData['objects']);
    final objectCounts = <String, int>{};

    // Count objects by class
    for (final obj in objects) {
      final className = obj['class'] ?? 'Unknown';
      objectCounts[className] = (objectCounts[className] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Detected ${objects.length} object${objects.length > 1 ? 's' : ''}:',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                objectCounts.entries.map((entry) {
                  return Chip(
                    backgroundColor: _getClassColor(entry.key).withOpacity(0.8),
                    label: Text(
                      '${entry.key} (${entry.value})',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    avatar: Icon(
                      _getClassIcon(entry.key),
                      color: Colors.white,
                      size: 16,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  // Show detailed view of history item
  void _showHistoryItemDetails(HistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle for dragging
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white30,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Title with event type
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: _getEventColor(item.eventType),
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.eventTypeString,
                                    style: AppTheme.subheadingStyle,
                                  ),
                                  Text(
                                    DateFormat(
                                      'EEEE, MMMM d, yyyy • h:mm a',
                                    ).format(item.timestamp),
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(color: Colors.white12),

                      // Content scrollable area
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            // Image if available
                            if (item.imageUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: item.imageUrl!,
                                  fit: BoxFit.cover,
                                  placeholder:
                                      (context, url) => Container(
                                        height: 200,
                                        color: Colors.black26,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        height: 200,
                                        color: Colors.black12,
                                        child: const Center(
                                          child: Icon(
                                            Icons.error_outline,
                                            size: 48,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Description
                            if (item.description != null) ...[
                              Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.description!,
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Detection details
                            if (item.eventType ==
                                    HistoryEventType.objectDetected &&
                                item.detectionData != null) ...[
                              Text(
                                'Detection Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildDetailedDetectionResults(
                                item.detectionData!,
                              ),
                            ],

                            // Status
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  'Status:',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        item.success
                                            ? Colors.green
                                            : Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item.success ? 'Success' : 'Failed',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Bottom action buttons
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Close',
                                style: TextStyle(color: AppTheme.accentColor),
                              ),
                            ),
                            if (item.imageUrl != null) ...[
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // TODO: Implement share functionality
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Share functionality not implemented',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  // Build detailed detection results
  Widget _buildDetailedDetectionResults(Map<String, dynamic> detectionData) {
    if (!detectionData.containsKey('objects') ||
        detectionData['objects'] is! List ||
        (detectionData['objects'] as List).isEmpty) {
      return const Text(
        'No objects detected',
        style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
      );
    }

    final objects = List<Map<String, dynamic>>.from(detectionData['objects']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary text
        Text(
          'Detected ${objects.length} object${objects.length > 1 ? 's' : ''}',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),

        // List of detected objects
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: objects.length,
          separatorBuilder:
              (context, index) =>
                  const Divider(color: Colors.white12, height: 16),
          itemBuilder: (context, index) {
            final obj = objects[index];
            final className = obj['class'] ?? 'Unknown';
            final confidence = obj['confidence'] ?? 0.0;

            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getClassColor(className).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getClassIcon(className),
                    color: _getClassColor(className),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (obj.containsKey('location'))
                        Text(
                          'Location: ${obj['location']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(confidence),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Show filter bottom sheet
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Center(
                        child: Text(
                          'Filter History',
                          style: AppTheme.subheadingStyle,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Event type filter
                      Text(
                        'Event Type',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
                                setModalState(() {
                                  _filterType = null;
                                });
                                setState(() {
                                  _filterType = null;
                                });
                              }
                            },
                            backgroundColor: Colors.white12,
                            selectedColor: AppTheme.primaryColor.withOpacity(
                              0.8,
                            ),
                            checkmarkColor: Colors.white,
                          ),
                          FilterChip(
                            label: const Text('Image Capture'),
                            selected:
                                _filterType == HistoryEventType.imageCaptured,
                            onSelected: (selected) {
                              setModalState(() {
                                _filterType =
                                    selected
                                        ? HistoryEventType.imageCaptured
                                        : null;
                              });
                              setState(() {
                                _filterType =
                                    selected
                                        ? HistoryEventType.imageCaptured
                                        : null;
                              });
                            },
                            backgroundColor: Colors.white12,
                            selectedColor: Colors.blue.withOpacity(0.8),
                            checkmarkColor: Colors.white,
                          ),
                          FilterChip(
                            label: const Text('Object Detection'),
                            selected:
                                _filterType == HistoryEventType.objectDetected,
                            onSelected: (selected) {
                              setModalState(() {
                                _filterType =
                                    selected
                                        ? HistoryEventType.objectDetected
                                        : null;
                              });
                              setState(() {
                                _filterType =
                                    selected
                                        ? HistoryEventType.objectDetected
                                        : null;
                              });
                            },
                            backgroundColor: Colors.white12,
                            selectedColor: Colors.purple.withOpacity(0.8),
                            checkmarkColor: Colors.white,
                          ),
                          FilterChip(
                            label: const Text('Trash Grabbed'),
                            selected:
                                _filterType == HistoryEventType.trashGrabbed,
                            onSelected: (selected) {
                              setModalState(() {
                                _filterType =
                                    selected
                                        ? HistoryEventType.trashGrabbed
                                        : null;
                              });
                              setState(() {
                                _filterType =
                                    selected
                                        ? HistoryEventType.trashGrabbed
                                        : null;
                              });
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
                        decoration: InputDecoration(
                          hintText: 'Search descriptions...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white70,
                          ),
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
                          setModalState(() {
                            _searchQuery = value;
                          });
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Apply & Clear buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                _filterType = null;
                                _searchQuery = '';
                              });
                              setState(() {
                                _filterType = null;
                                _searchQuery = '';
                              });
                            },
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
                ),
          ),
    );
  }

  // Get color based on event type
  Color _getEventColor(HistoryEventType eventType) {
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
  IconData _getClassIcon(String className) {
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

  Color _getClassColor(String className) {
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

  Color _getConfidenceColor(double confidence) {
    if (confidence < 0.5) {
      return Colors.red;
    } else if (confidence < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
