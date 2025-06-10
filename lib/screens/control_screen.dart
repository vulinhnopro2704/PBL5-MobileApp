import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_v2/config/env_config.dart';

import '../services/websocket_service.dart';
import '../services/log_service.dart';
import '../services/ai_service.dart';

import '../config/app_theme.dart';
import '../constants/command_types.dart';
import '../widgets/control/connection_status_card.dart';
import '../widgets/control/robot_response_card.dart';
import '../widgets/control/camera_panel.dart';
import '../widgets/control/control_buttons_panel.dart';
import '../widgets/control/simple_grab_button.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen>
    with TickerProviderStateMixin {
  final WebSocketService _webSocketService = WebSocketService();
  final AiService _aiService = AiService();

  // Stream subscriptions to be managed
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionStatusSubscription;

  String _status = 'Disconnected';
  bool _isConnecting = false;
  late AnimationController _connectionAnimController;

  // For enabling long-press functionality
  String? _activeCommand;
  Timer? _commandTimer;

  // Camera and AI related
  String? _imageUrl;
  bool _isCameraLoading = false;
  bool _isDetecting = false;
  List<Map<String, dynamic>> _detectedObjects = [];
  bool _showCamera = false; // Toggle to show/hide camera panel

  // Add this new property to store the latest response from the robot
  Map<String, dynamic>? _lastRobotResponse;
  Timer? _responseDisplayTimer;

  Timer? _continuousCommandTimer;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _connectionAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _connectWebSocket();

    // Listen for WebSocket messages with proper subscription management
    _messageSubscription = _webSocketService.messageStream.listen((message) {
      LogService.info('Message from server: $message');
      // Update UI based on message if needed
      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          // Store the latest response
          if (message is Map<String, dynamic>) {
            _lastRobotResponse = message;

            // Clear the response after a few seconds
            _responseDisplayTimer?.cancel();
            _responseDisplayTimer = Timer(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _lastRobotResponse = null;
                });
              }
            });
          } else if (message is String && message.contains('status')) {
            _status = 'Connected: $message';
          }
        });
      }
    });

    // Listen for connection status changes with proper subscription management
    _connectionStatusSubscription = _webSocketService.connectionStatusStream
        .listen((isConnected) {
          if (mounted) {
            // Check if the widget is still in the tree
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
          }
        });

    // Auto-connect timer with proper lifecycle check
    _continuousCommandTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      if (_status == 'Disconnected' && EnvConfig.isInitialized) {
        _connectWebSocket();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Cancel stream subscriptions
    _messageSubscription?.cancel();
    _connectionStatusSubscription?.cancel();

    _webSocketService.dispose();
    _connectionAnimController.dispose();
    _stopContinuousCommand();
    _responseDisplayTimer?.cancel();
    _continuousCommandTimer?.cancel();
    super.dispose();
  }

  // Stop any continuous commands in progress
  void _stopContinuousCommand() {
    // Cancel command timer if it exists
    _commandTimer?.cancel();
    _commandTimer = null;

    // Only call setState if widget is still mounted and not disposed
    if (mounted && !_isDisposed) {
      setState(() {
        _activeCommand = null;
      });
    }

    // Send stop command to robot if needed
    if (_webSocketService.isConnected) {
      _webSocketService.sendCommand(DirectionCommand.stop.value);
    }
  }

  Future<void> _connectWebSocket() async {
    if (_isDisposed || !mounted) return;

    setState(() {
      _isConnecting = true;
      _status = 'Connecting...';
      _connectionAnimController.repeat();
    });

    try {
      final bool connected = await _webSocketService.connect();

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _status = connected ? 'Connected' : 'Connection failed';
          if (connected) {
            _connectionAnimController.stop();
          } else {
            _connectionAnimController.reset();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Could not connect to the robot. Please check if the robot is powered on and connected to the network.',
                        style: AppTheme.bodyStyle,
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.errorColor,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _status = 'Connection error';
          _connectionAnimController.reset();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connection error: ${e.toString()}',
                      style: AppTheme.bodyStyle,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        });
      }
    }
  }

  void _sendCommand(String command) {
    // Log the command first thing
    LogService.info('ROBOT COMMAND: $command');

    if (!_webSocketService.isConnected) {
      LogService.warning('Cannot send command: Not connected to server');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Not connected to server',
                  style: AppTheme.bodyStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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

    // Handle special commands with confirmation
    if (command == ActionCommand.resetBin.value) {
      _showConfirmationDialog(
        'Reset Bin',
        'Are you sure you want to reset the bin to its original position?',
        () => _webSocketService.resetBin(),
      );
      return;
    } else if (command == ActionCommand.cleanBin.value) {
      _showConfirmationDialog(
        'Clean Bin',
        'Mark all trash in the bin as collected?',
        () => _webSocketService.cleanBin(),
      );
      return;
    }

    // Check if this is a continuous command that requires holding
    if (command == DirectionCommand.forward.value ||
        command == DirectionCommand.backward.value ||
        command == DirectionCommand.left.value ||
        command == DirectionCommand.right.value) {
      setState(() {
        _activeCommand = command;
      });
    }

    // Send command to websocket service
    _webSocketService.sendCommand(command);

    // Provide haptic feedback
    HapticFeedback.mediumImpact();
  }

  // Show confirmation dialog for important actions
  void _showConfirmationDialog(
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            title,
            style: AppTheme.headingStyle.copyWith(fontSize: 18),
          ),
          content: Text(message, style: AppTheme.bodyStyle),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTheme.buttonTextStyle.copyWith(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
                HapticFeedback.mediumImpact();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('$title command sent', style: AppTheme.bodyStyle),
                      ],
                    ),
                    backgroundColor: AppTheme.connectedColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black87,
              ),
              child: Text(
                'Confirm',
                style: AppTheme.buttonTextStyle.copyWith(color: Colors.black87),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _captureImage() async {
    setState(() {
      _isCameraLoading = true;
      _detectedObjects = [];
    });

    try {
      // Create a completer to handle the async response
      final completer = Completer<String?>();

      // Store the current subscription to avoid memory leaks
      StreamSubscription? cameraResponseSubscription;

      // Set a timeout
      final timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          LogService.warning('Camera capture timed out');
          cameraResponseSubscription?.cancel();
          completer.complete(null);
        }
      });

      // Listen for the camera response from WebSocket
      cameraResponseSubscription = _webSocketService.messageStream.listen((
        message,
      ) {
        if (message is Map<String, dynamic> &&
            message['status'] == 'success' &&
            message['message'] == 'Take picture' &&
            message.containsKey('response')) {
          // Cancel the timeout
          timeoutTimer.cancel();

          // Extract image URL from the response
          final response = message['response'];
          String? imageUrl;

          if (response is Map<String, dynamic> &&
              response.containsKey('imageUrl')) {
            imageUrl = response['imageUrl'] as String?;
          } else if (response is Map<String, dynamic> &&
              response.containsKey('url')) {
            imageUrl = response['url'] as String?;
          }

          if (!completer.isCompleted) {
            LogService.info('Received camera image: $imageUrl');
            completer.complete(imageUrl);
          }

          // We can cancel the subscription now
          cameraResponseSubscription?.cancel();
        }
      });

      // Send the take_picture command via WebSocket
      _webSocketService.sendCommand('take_picture');
      LogService.info('Sent take_picture command via WebSocket');

      // Wait for the response or timeout
      final imageUrl = await completer.future;

      // Clean up
      timeoutTimer.cancel();
      cameraResponseSubscription.cancel();

      // Check if widget is still mounted before updating state
      if (!mounted) return;

      setState(() {
        _imageUrl = imageUrl;
        _isCameraLoading = false;
        if (imageUrl != null) {
          _showCamera = true; // Show camera panel when image is captured
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to capture image or no image returned'),
              backgroundColor: Colors.orange,
            ),
          );
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
      // Use AI service for detection
      final result = await _aiService.detectObjects(imageUrl: _imageUrl);

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
                ConnectionStatusCard(
                  isConnected: _webSocketService.isConnected,
                  isConnecting: _isConnecting,
                  status: _status,
                  onReconnect: _connectWebSocket,
                ),

                // Add Robot Response Card if there's a response
                if (_lastRobotResponse != null) ...[
                  const SizedBox(height: 8),
                  RobotResponseCard(response: _lastRobotResponse!),
                ],

                const SizedBox(height: 16),

                // Camera and AI controls section
                if (_showCamera) ...[
                  Expanded(
                    child: CameraPanel(
                      imageUrl: _imageUrl,
                      isCameraLoading: _isCameraLoading,
                      isDetecting: _isDetecting,
                      detectedObjects: _detectedObjects,
                      onCapture: _captureImage,
                      onDetect: _detectObjects,
                      onClose: () {
                        setState(() {
                          _showCamera = false;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                ],

                // Control buttons
                if (!_showCamera)
                  Expanded(
                    child: ControlButtonsPanel(
                      onSendCommand: _sendCommand,
                      activeCommand: _activeCommand,
                    ),
                  ),

                // Show minimal controls when camera is active
                if (_showCamera)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [SimpleGrabButton(onSendCommand: _sendCommand)],
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
}
