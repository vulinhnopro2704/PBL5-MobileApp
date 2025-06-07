import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/history_item.dart';
import '../services/history_service.dart';
import '../services/log_service.dart';
import '../widgets/history/history_card.dart';
import '../widgets/history/history_detail_view.dart';
import '../widgets/history/history_filter_bar.dart';
import '../widgets/history/history_filter_sheet.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  List<HistoryItem> _historyItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _error;

  // Filter options
  HistoryEventType? _filterType;
  String _searchQuery = '';

  // Scroll controller for infinite scrolling
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll listener to detect when to load more items
  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreHistory();
    }
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
        _hasMoreData =
            history.length >= 20; // If we got a full page, assume there's more
      });
    } catch (e) {
      LogService.error('Failed to load history', e);
      setState(() {
        _error = 'Failed to load history: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreHistory() async {
    if (_historyItems.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final moreItems = await _historyService.getNextPage(_historyItems.last);

      setState(() {
        _historyItems.addAll(moreItems);
        _isLoadingMore = false;
        _hasMoreData =
            moreItems.length >=
            20; // If we got a full page, assume there's more
      });
    } catch (e) {
      LogService.error('Failed to load more history', e);
      setState(() {
        _isLoadingMore = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more items: ${e.toString()}')),
        );
      }
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

  // Clear all history - kept for UI compatibility

  void _showHistoryItemDetails(HistoryItem item) {
    try {
      // Log item data before showing details
      LogService.debug(
        'Showing history item details',
        'ID: ${item.id}, EventType: ${item.eventType}, HasData: ${item.detectionData != null}',
      );

      // If there's detection data, validate its structure
      if (item.detectionData != null) {
        LogService.debug(
          'Detection data keys',
          item.detectionData!.keys.join(", "),
        );

        if (item.detectionData!.containsKey('detections')) {
          var detectionsData = item.detectionData!['detections'];
          // Log as simple text
          LogService.debug(
            'Detections structure',
            'Type: ${detectionsData.runtimeType}, Content: $detectionsData',
          );

          // Check if detectionsData is a Map or a List
          String structureInfo = "";
          if (detectionsData is Map) {
            structureInfo = "Map with keys: ${detectionsData.keys.join(", ")}";
          } else if (detectionsData is List) {
            structureInfo = "List with ${detectionsData.length} items";
          } else {
            structureInfo =
                "Neither Map nor List but ${detectionsData.runtimeType}";
          }
          LogService.debug('Detections structure info', structureInfo);
        } else {
          LogService.debug(
            'Available detection data keys',
            item.detectionData!.keys.join(", "),
          );
        }
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          // Wrap the HistoryDetailView in a try-catch to prevent crashes
          try {
            return HistoryDetailView(item: item);
          } catch (e) {
            LogService.error('Error building HistoryDetailView', e);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error displaying details',
                    style: AppTheme.headingStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'There was an error processing the detection data: ${e.toString()}',
                    style: AppTheme.bodyStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          }
        },
      );
    } catch (e) {
      LogService.error('Failed to show history detail view', e);

      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error displaying details: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => HistoryFilterSheet(
            initialFilterType: _filterType,
            initialSearchQuery: _searchQuery,
            onFiltersChanged: (type, query) {
              setState(() {
                _filterType = type;
                _searchQuery = query;
              });
            },
          ),
    );
  }

  void _clearFilters() {
    setState(() {
      _filterType = null;
      _searchQuery = '';
    });
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
          // Removed clear history button since it's not supported with Firestore
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(child: _buildContent()),
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
              onPressed: _clearFilters,
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

    return Column(
      children: [
        // Show filter indicator if filters are active
        HistoryFilterBar(
          filterType: _filterType,
          searchQuery: _searchQuery,
          filteredCount: filteredItems.length,
          totalCount: _historyItems.length,
          onClearFilters: _clearFilters,
        ),

        // Main history list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: filteredItems.length + (_isLoadingMore ? 1 : 0),
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              if (index == filteredItems.length) {
                // Show loading indicator at the bottom
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final item = filteredItems[index];
              return HistoryCard(
                item: item,
                onViewDetails: _showHistoryItemDetails,
              );
            },
          ),
        ),
      ],
    );
  }
}
