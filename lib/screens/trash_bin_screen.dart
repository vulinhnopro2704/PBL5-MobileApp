import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/trash_bin_model.dart';
import '../services/trash_bin_service.dart';
import '../services/log_service.dart';
import '../widgets/trash_bin/trash_compartment_card.dart';
import '../widgets/trash_bin/trash_bin_overview.dart';
import '../widgets/trash_bin/action_buttons.dart';

class TrashBinScreen extends StatefulWidget {
  const TrashBinScreen({super.key});

  @override
  State<TrashBinScreen> createState() => _TrashBinScreenState();
}

class _TrashBinScreenState extends State<TrashBinScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final TrashBinService _trashBinService = TrashBinService();
  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeService();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isDisposed && _trashBinService.isInitialized) {
          _trashBinService.resume();
        }
        break;
      case AppLifecycleState.paused:
        if (!_isDisposed) {
          _trashBinService.pause();
        }
        break;
      default:
        break;
    }
  }

  void _initializeService() {
    if (mounted && !_isDisposed) {
      try {
        _trashBinService.initialize();
      } catch (e) {
        LogService.error('Failed to initialize TrashBinService in screen', e);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _trashBinService.pause();
    super.dispose();
  }

  Future<void> _resetTrashBin() async {
    if (!mounted || _isDisposed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _trashBinService.resetTrashBin();
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trash bin reset successfully'),
            backgroundColor: AppTheme.connectedColor,
          ),
        );
      }
    } catch (e) {
      LogService.error('Failed to reset trash bin', e);
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reset trash bin'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: StreamBuilder<TrashBinData>(
            stream: _trashBinService.dataStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorWidget(snapshot.error.toString());
              }

              if (!snapshot.hasData) {
                return _buildLoadingWidget();
              }

              final data = snapshot.data!;
              return _buildContent(data);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(TrashBinData data) {
    return RefreshIndicator(
      onRefresh: () async {
        if (!_trashBinService.isInitialized) {
          _initializeService();
        } else {
          _trashBinService.resume();
        }
        await Future.delayed(const Duration(seconds: 1));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App bar
            Row(
              children: [
                Text(
                  '🗑️ Trash Monitor',
                  style: AppTheme.headingStyle.copyWith(fontSize: 28),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.connectedColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Live',
                        style: AppTheme.buttonTextStyle.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Overview card
            TrashBinOverview(data: data),

            const SizedBox(height: 24),

            // Compartments grid
            Text(
              'Compartments',
              style: AppTheme.subheadingStyle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio:
                  1.1, // Increased from 1.0 to 1.1 for more vertical space
              children: [
                TrashCompartmentCard(
                  type: TrashType.metal,
                  count: data.metal,
                  color: Colors.blueGrey,
                ),
                TrashCompartmentCard(
                  type: TrashType.plastic,
                  count: data.plastic,
                  color: Colors.blue,
                ),
                TrashCompartmentCard(
                  type: TrashType.paper,
                  count: data.paper,
                  color: Colors.green,
                ),
                TrashCompartmentCard(
                  type: TrashType.other,
                  count: data.other,
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons
            TrashBinActionButtons(
              onReset: _resetTrashBin,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Loading trash bin data...',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 64),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: AppTheme.headingStyle.copyWith(color: AppTheme.errorColor),
          ),
          const SizedBox(height: 8),
          Text(error, style: AppTheme.bodyStyle, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _initializeService();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
