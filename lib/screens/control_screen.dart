import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/websocket_service.dart';
import '../services/log_service.dart';
import '../services/api_service.dart';
import '../widgets/control_button.dart';
import '../config/app_theme.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with TickerProviderStateMixin {
  final WebSocketService _webSocketService = WebSocketService();
  final ApiService _apiService = ApiService();

  String _status = 'Disconnected';
  bool _isConnecting = false;
  late AnimationController _connectionAnimController;

  // For enabling long-press functionality
  bool _isHoldingButton = false;
  String? _activeCommand;
  Timer? _commandTimer;

  // Camera and AI related
  String? _imageUrl;
  bool _isCameraLoading = false;
  bool _isDetecting = false;
  List<Map<String, dynamic>> _detectedObjects = [];
  bool _showCamera = false; // Toggle to show/hide camera panel

  @override
  void initState() {
    super.initState();
    _connectionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _connectWebSocket();

    // Listen for WebSocket messages
    _webSocketService.messageStream.listen((message) {
      LogService.info('Message from server: $message');
      // Update UI based on message if needed
      setState(() {
        // Example: parse status message
        if (message is String && message.contains('status')) {
          _status = 'Connected: $message';
        }
      });
    });

    // Listen for connection status changes
    _webSocketService.connectionStatusStream.listen((isConnected) {
      setState(() {
        if (isConnected) {
          _status = 'Connected';
          _isConnecting = false;
          _connectionAnimController.stop();
        } else {
          _status = 'Disconnected';
          _stopContinuousCommand();
        }
      });
    });
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    _connectionAnimController.dispose();
    _stopContinuousCommand();
    super.dispose();
  }

  Future<void> _connectWebSocket() async {
    setState(() {
      _isConnecting = true;
      _status = 'Connecting...';
      _connectionAnimController.repeat();
    });

    final bool connected = await _webSocketService.connect();

    setState(() {
      _isConnecting = false;
      _status = connected ? 'Connected' : 'Connection failed';
      if (connected) {
        _connectionAnimController.stop();
      } else {
        _connectionAnimController.reset();
      }
    });
  }

  void _sendCommand(String command) {
    if (!_webSocketService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Text('Not connected to server', style: AppTheme.bodyStyle),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'CONNECT',
            textColor: Colors.white,
            onPressed: _connectWebSocket,
          ),
        ),
      );
      return;
    }

    LogService.info('Sending command: $command');
    _webSocketService.send({'command': command});

    // Record trash grab events
    if (command == 'grab_trash') {
      _apiService.recordTrashGrab(
        success: true,
        imageUrl: _imageUrl,
        description: 'User initiated trash grab operation',
      );
    }

    // Provide haptic feedback
    HapticFeedback.mediumImpact();
  }

  // For continuous commands (holding a button)
  void _startContinuousCommand(String command) {
    if (_isHoldingButton) return;

    setState(() {
      _isHoldingButton = true;
      _activeCommand = command;
    });

    _sendCommand(command);

    // Send the command repeatedly while button is held
    _commandTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_isHoldingButton) {
        _sendCommand(command);
      } else {
        timer.cancel();
      }
    });
  }

  void _stopContinuousCommand() {
    if (_commandTimer != null) {
      _commandTimer!.cancel();
      _commandTimer = null;
    }

    if (_isHoldingButton && _activeCommand != null) {
      _sendCommand(
        'stop',
      ); // Send stop command when releasing a movement button
      setState(() {
        _isHoldingButton = false;
        _activeCommand = null;
      });
    }
  }

  Future<void> _captureImage() async {
    setState(() {
      _isCameraLoading = true;
      _detectedObjects = [];
    });

    try {
      final imageUrl = await _apiService.captureImage();

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _imageUrl = imageUrl;
        _isCameraLoading = false;
        if (imageUrl != null) {
          _showCamera = true; // Show camera panel when image is captured
        }
      });
    } catch (e) {
      LogService.error('Error capturing image', e);

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _isCameraLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _detectObjects() async {
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture an image first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isDetecting = true;
      _detectedObjects = [];
    });

    try {
      final result = await _apiService.detectObjects();

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _isDetecting = false;
        if (result != null && result.containsKey('objects')) {
          _detectedObjects = List<Map<String, dynamic>>.from(result['objects']);
        }
      });
    } catch (e) {
      LogService.error('Error detecting objects', e);

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _isDetecting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error detecting objects: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Robot Control'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Camera toggle button
          IconButton(
            icon: Icon(
              _showCamera ? Icons.camera_alt : Icons.camera_alt_outlined,
            ),
            onPressed: () {
              setState(() {
                _showCamera = !_showCamera;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Status card
                Container(
                  decoration: AppTheme.cardDecoration,
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      _isConnecting
                          ? SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.connectingColor,
                              ),
                              strokeWidth: 3,
                            ),
                          )
                          : Icon(
                            _webSocketService.isConnected
                                ? Icons.wifi
                                : Icons.wifi_off,
                            color:
                                _webSocketService.isConnected
                                    ? AppTheme.connectedColor
                                    : AppTheme.disconnectedColor,
                            size: 32,
                          ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connection Status',
                              style: AppTheme.subheadingStyle,
                            ),
                            Text(_status, style: AppTheme.bodyStyle),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isConnecting ? null : _connectWebSocket,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          _isConnecting ? 'Connecting...' : 'Reconnect',
                          style: AppTheme.buttonTextStyle,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          disabledBackgroundColor: AppTheme.primaryColor
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Camera and AI controls section
                if (_showCamera) ...[
                  Expanded(
                    child: Container(
                      decoration: AppTheme.cardDecoration,
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title with close button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.camera, color: Colors.white),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Camera & AI',
                                    style: AppTheme.subheadingStyle,
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showCamera = false;
                                  });
                                },
                                iconSize: 20,
                                splashRadius: 20,
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24),

                          // Make the rest of the content scrollable
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Image display area
                                  AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child:
                                          _isCameraLoading
                                              ? const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                              : _imageUrl != null
                                              ? Stack(
                                                children: [
                                                  // Image
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: CachedNetworkImage(
                                                      imageUrl: _imageUrl!,
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                      placeholder:
                                                          (
                                                            context,
                                                            url,
                                                          ) => const Center(
                                                            child:
                                                                CircularProgressIndicator(),
                                                          ),
                                                      errorWidget:
                                                          (
                                                            context,
                                                            url,
                                                            error,
                                                          ) => const Center(
                                                            child: Icon(
                                                              Icons.error,
                                                              color: Colors.red,
                                                              size: 50,
                                                            ),
                                                          ),
                                                    ),
                                                  ),

                                                  // Object detection boxes
                                                  if (_detectedObjects
                                                      .isNotEmpty)
                                                    Positioned.fill(
                                                      child: CustomPaint(
                                                        painter:
                                                            ObjectDetectionPainter(
                                                              objects:
                                                                  _detectedObjects,
                                                            ),
                                                      ),
                                                    ),

                                                  // Loading overlay when detecting
                                                  if (_isDetecting)
                                                    Positioned.fill(
                                                      child: Container(
                                                        color: Colors.black54,
                                                        child: const Center(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              CircularProgressIndicator(),
                                                              SizedBox(
                                                                height: 16,
                                                              ),
                                                              Text(
                                                                'Detecting objects...',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              )
                                              : const Center(
                                                child: Text(
                                                  'No image captured',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Camera control buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isCameraLoading
                                                  ? null
                                                  : _captureImage,
                                          icon: const Icon(Icons.camera_alt),
                                          label: Text(
                                            _isCameraLoading
                                                ? 'Capturing...'
                                                : 'Capture Image',
                                            style: AppTheme.buttonTextStyle,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _isDetecting || _imageUrl == null
                                                  ? null
                                                  : _detectObjects,
                                          icon: const Icon(Icons.search),
                                          label: Text(
                                            _isDetecting
                                                ? 'Detecting...'
                                                : 'Detect Objects',
                                            style: AppTheme.buttonTextStyle,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.accentColor,
                                            foregroundColor: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Display detection results
                                  if (_detectedObjects.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          _detectedObjects.map((obj) {
                                            final String label =
                                                obj['class'] ?? 'Unknown';
                                            final double confidence =
                                                obj['confidence'] ?? 0.0;
                                            final Color chipColor =
                                                _getClassColor(label);

                                            return Chip(
                                              label: Text(
                                                '$label (${(confidence * 100).toStringAsFixed(1)}%)',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              backgroundColor: chipColor,
                                              avatar: Icon(
                                                _getClassIcon(label),
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                // Control buttons
                if (!_showCamera)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Forward button
                          GestureDetector(
                            onLongPress:
                                () => _startContinuousCommand('forward'),
                            onLongPressEnd: (_) => _stopContinuousCommand(),
                            child: ControlButton(
                              icon: Icons.arrow_upward,
                              label: 'Forward',
                              onPressed: () => _sendCommand('forward'),
                              color: AppTheme.forwardButtonColor,
                              isPressed: _activeCommand == 'forward',
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Left, Stop, Right buttons in a row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onLongPress:
                                    () => _startContinuousCommand('left'),
                                onLongPressEnd: (_) => _stopContinuousCommand(),
                                child: ControlButton(
                                  icon: Icons.arrow_back,
                                  label: 'Left',
                                  onPressed: () => _sendCommand('left'),
                                  color: AppTheme.leftButtonColor,
                                  isPressed: _activeCommand == 'left',
                                ),
                              ),
                              const SizedBox(width: 16),
                              ControlButton(
                                icon: Icons.stop_circle,
                                label: 'Stop',
                                onPressed: () => _sendCommand('stop'),
                                color: AppTheme.stopButtonColor,
                                isPressed: false,
                                isGlowing: true,
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onLongPress:
                                    () => _startContinuousCommand('right'),
                                onLongPressEnd: (_) => _stopContinuousCommand(),
                                child: ControlButton(
                                  icon: Icons.arrow_forward,
                                  label: 'Right',
                                  onPressed: () => _sendCommand('right'),
                                  color: AppTheme.rightButtonColor,
                                  isPressed: _activeCommand == 'right',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Backward button
                          GestureDetector(
                            onLongPress:
                                () => _startContinuousCommand('backward'),
                            onLongPressEnd: (_) => _stopContinuousCommand(),
                            child: ControlButton(
                              icon: Icons.arrow_downward,
                              label: 'Backward',
                              onPressed: () => _sendCommand('backward'),
                              color: AppTheme.backwardButtonColor,
                              isPressed: _activeCommand == 'backward',
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Action buttons row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ControlButton(
                                icon: Icons.rotate_right,
                                label: 'Rotate Bin',
                                onPressed: () => _sendCommand('rotate_bin'),
                                color: AppTheme.rotateButtonColor,
                              ),
                              const SizedBox(width: 24),
                              ControlButton(
                                icon: Icons.pan_tool,
                                label: 'Grab Trash',
                                onPressed: () => _sendCommand('grab_trash'),
                                color: AppTheme.grabButtonColor,
                                isLarge: true,
                                isGlowing: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                // Show minimal controls when camera is active
                if (_showCamera)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ControlButton(
                        icon: Icons.stop_circle,
                        label: 'Stop',
                        onPressed: () => _sendCommand('stop'),
                        color: AppTheme.stopButtonColor,
                        isGlowing: true,
                      ),
                      const SizedBox(width: 16),
                      ControlButton(
                        icon: Icons.pan_tool,
                        label: 'Grab',
                        onPressed: () => _sendCommand('grab_trash'),
                        color: AppTheme.grabButtonColor,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton:
          !_showCamera
              ? FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _showCamera = true;
                  });
                },
                backgroundColor: AppTheme.accentColor,
                child: const Icon(Icons.camera_alt),
              )
              : null,
    );
  }

  // Helper methods for object detection visualization
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
}

// Custom painter for drawing bounding boxes
class ObjectDetectionPainter extends CustomPainter {
  final List<Map<String, dynamic>> objects;

  ObjectDetectionPainter({required this.objects});

  @override
  void paint(Canvas canvas, Size size) {
    for (var obj in objects) {
      // Get bounding box coordinates (normalized from 0 to 1)
      final List<dynamic> boxData = obj['bbox'] ?? [0, 0, 0, 0];
      final double x = boxData[0] * size.width;
      final double y = boxData[1] * size.height;
      final double w = boxData[2] * size.width;
      final double h = boxData[3] * size.height;

      final String label = obj['class'] ?? 'Unknown';
      final double confidence = obj['confidence'] ?? 0.0;

      // Create rectangle
      final rect = Rect.fromLTWH(x, y, w, h);

      // Create paint for the box
      final paint =
          Paint()
            ..color = _getBoxColor(label)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

      // Draw box
      canvas.drawRect(rect, paint);

      // Draw label background
      final textPaint = Paint()..color = _getBoxColor(label);

      canvas.drawRect(Rect.fromLTWH(x, y - 20, w, 20), textPaint);

      // Draw label text
      final textSpan = TextSpan(
        text: ' $label ${(confidence * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(minWidth: 0, maxWidth: w);
      textPainter.paint(canvas, Offset(x, y - 18));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  Color _getBoxColor(String className) {
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
}
