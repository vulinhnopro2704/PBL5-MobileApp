import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/subjects.dart';

import '../config/env_config.dart';
import '../constants/command_types.dart';
import '../utils/network_utils.dart';
import 'log_service.dart';
import 'firebase_service.dart'; // Add this import

class WebSocketService {
  // Singleton instance
  static WebSocketService? _instance;
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  // Private constructor for singleton
  WebSocketService._internal();

  // Factory constructor that returns singleton instance
  factory WebSocketService() {
    return instance;
  }

  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  int _reconnectAttempt = 0;

  // Stream controllers
  final _messageController = BehaviorSubject<dynamic>();
  final _connectionStatusController = BehaviorSubject<bool>.seeded(false);

  // Robot state
  bool _isPoweredOn = true;
  bool _isAutoMode = false;
  int _speed = 50;
  int _binStatus = 0;
  String _currentMode = 'manual';

  // Getters
  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool get isConnected => _isConnected;
  bool get isPoweredOn => _isPoweredOn;
  bool get isAutoMode => _isAutoMode;
  int get speed => _speed;
  int get binStatus => _binStatus;
  String get currentMode => _currentMode;

  // Connect to WebSocket server
  Future<bool> connect() async {
    if (_isConnected && _channel != null) {
      LogService.info('Already connected to WebSocket server');
      // Let's verify the connection is actually alive
      try {
        final connectData = {'direction': 'connect', 'speed': _speed};
        _channel!.sink.add(jsonEncode(connectData));
        LogService.info('Sent connection verification command');
        return true;
      } catch (e) {
        LogService.warning('Connection verification failed, reconnecting...');
        disconnect(); // Force disconnect to reconnect properly
      }
    }

    // Clear any existing reconnect timer
    _reconnectTimer?.cancel();

    try {
      // Resolve the Raspberry Pi's mDNS address
      String wsUrl = EnvConfig.wsUrl;

      // Check if the URL contains .local and needs resolution
      if (wsUrl.contains('.local')) {
        LogService.info('mDNS address detected in WebSocket URL, resolving...');

        final String? resolvedIP = await NetworkUtils.resolveRaspberryPiLocal();
        if (resolvedIP == null) {
          LogService.error('Failed to resolve Raspberry Pi IP address');
          _handleDisconnection();
          return false;
        }

        // Replace the .local hostname with the resolved IP
        final Uri originalUri = Uri.parse(wsUrl);
        wsUrl = wsUrl.replaceFirst(originalUri.host, resolvedIP);

        LogService.info('Resolved WebSocket URL: $wsUrl');
      }

      LogService.info('Connecting to WebSocket server: $wsUrl');

      // Create a completer to handle the connection timeout
      final completer = Completer<bool>();

      // Set up a connection timeout
      final timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.complete(false);
          LogService.error('WebSocket connection timeout');
        }
      });

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Test the connection with a connect message
      bool receivedResponse = false;

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          if (!receivedResponse && !completer.isCompleted) {
            receivedResponse = true;
            completer.complete(true);
            timeoutTimer.cancel();
          }
          _handleMessage(message);
        },
        onError: (error) {
          LogService.error('WebSocket error', error);
          if (!completer.isCompleted) {
            completer.complete(false);
            timeoutTimer.cancel();
          }
          _handleDisconnection();
        },
        onDone: () {
          LogService.info('WebSocket connection closed');
          if (!completer.isCompleted) {
            completer.complete(false);
            timeoutTimer.cancel();
          }
          _handleDisconnection();
        },
      );

      // Send a connect command to verify connection and get robot state
      try {
        final connectData = {'direction': 'connect', 'speed': _speed};
        _channel!.sink.add(jsonEncode(connectData));
        LogService.info('Sent connect command: $connectData');
      } catch (e) {
        LogService.error('Failed to send connect command', e);
        if (!completer.isCompleted) {
          completer.complete(false);
          timeoutTimer.cancel();
        }
      }

      // Wait for the connection to be established or timeout
      final connected = await completer.future;

      // Update connection status based on actual connection
      _isConnected = connected;
      _connectionStatusController.add(_isConnected);

      if (connected) {
        LogService.info('Successfully connected to WebSocket server');
        _reconnectAttempt =
            0; // Reset reconnect attempts on successful connection
      } else {
        LogService.error('Failed to establish WebSocket connection');
        _handleDisconnection();
      }

      return connected;
    } catch (e) {
      LogService.error('Failed to connect to WebSocket server', e);
      _handleDisconnection();
      return false;
    }
  }

  // Disconnect from WebSocket server
  void disconnect() {
    LogService.info('Disconnecting WebSocket...');

    if (_channel != null) {
      try {
        _channel!.sink.close();
      } catch (e) {
        LogService.warning('Error closing WebSocket channel: $e');
      }
      _channel = null;
    }

    // Only add to stream if not disposed and stream is not closed
    if (!_isDisposed && !_connectionStatusController.isClosed) {
      _connectionStatusController.add(false);
    }

    _isConnected = false;
    LogService.info('WebSocket disconnected');
  }

  // Handle reconnection on disconnect
  void _handleDisconnection() {
    LogService.warning('WebSocket connection lost');
    _isConnected = false;
    _channel = null;

    // Only add to stream if not disposed and stream is not closed
    if (!_isDisposed && !_connectionStatusController.isClosed) {
      _connectionStatusController.add(false);
    }
  }

  // Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      LogService.info('Message from server: $message');

      // Parse the message
      if (message is String) {
        try {
          final data = jsonDecode(message);
          _messageController.add(data);

          // Update robot state based on received data
          if (data is Map<String, dynamic>) {
            // Update mode from server response
            if (data.containsKey('mode')) {
              final serverMode = data['mode'] as String;
              _currentMode = serverMode;
              _isAutoMode = serverMode == 'auto';
              LogService.info('Robot mode updated to: $serverMode');
            }

            // Update other robot states
            if (data.containsKey('binStatus')) {
              _binStatus = data['binStatus'];
            }
            if (data.containsKey('isAutoMode')) {
              _isAutoMode = data['isAutoMode'];
            }
            if (data.containsKey('speed')) {
              _speed = data['speed'];
            }
            if (data.containsKey('isPoweredOn')) {
              _isPoweredOn = data['isPoweredOn'];
            }

            // Also update speed if it comes from a move command
            if (data.containsKey('status') &&
                data['status'] == 'success' &&
                data.containsKey('direction') &&
                data.containsKey('speed')) {
              _speed = data['speed'];
            } // Log detailed response information
            if (data.containsKey('status')) {
              final status = data['status'];
              final action = data['direction'] ?? 'unknown';
              LogService.info('Robot response: $status - $action');

              // Handle specific bin-related responses
              if (action == 'reset_bin' && status == 'success') {
                _binStatus = 0; // Reset to original position
                LogService.info('Bin successfully reset to original position');
              } else if (action == 'clean_bin' && status == 'success') {
                _binStatus = 0; // Reset bin status after cleaning
                LogService.info('Bin marked as clean - all trash collected');
              } else if (action == 'rotate_bin' && status == 'success') {
                // You might want to update bin status based on rotation
                LogService.info('Bin rotation completed');
              }
            }
          }
        } catch (e) {
          LogService.error('Error parsing JSON message', e);
          _messageController.add(message);
        }
      } else {
        _messageController.add(message);
      }
    } catch (e) {
      LogService.error('Error handling WebSocket message', e);
    }
  }

  // Send a generic message
  void send(dynamic data) {
    if (_isConnected && _channel != null) {
      try {
        final jsonString = jsonEncode(data);
        _channel!.sink.add(jsonString);
        LogService.info('Sent: $jsonString');
      } catch (e) {
        LogService.error('Error sending WebSocket message', e);
      }
    } else {
      LogService.error('Cannot send message: WebSocket not connected');
    }
  }

  // Send a command with the current speed
  void sendCommand(String command) {
    if (_isConnected && _channel != null) {
      try {
        // Make sure we're not sending an empty direction
        if (command.isEmpty) {
          LogService.warning('Attempted to send empty command, ignoring');
          return;
        }

        final data = {'direction': command, 'speed': _speed};
        LogService.info('Sending WS command: $data');
        send(data);
      } catch (e) {
        LogService.error('Error sending WebSocket command', e);
      }
    } else {
      LogService.error('Cannot send command: WebSocket not connected');
    }
  }

  // Send a direction command
  void sendDirectionCommand(DirectionCommand command) {
    sendCommand(command.value);
  }

  // Send an action command
  void sendActionCommand(ActionCommand command) {
    sendCommand(command.value);
  }

  // Send a mode command
  void sendModeCommand(ModeCommand command) {
    final commandValue = command.value;
    LogService.info('Sending mode command: $commandValue');

    // Update local state before sending the command
    String firebaseMode;
    if (command == ModeCommand.autoMode) {
      _isAutoMode = true;
      _currentMode = 'auto';
      firebaseMode = 'auto';
      sendCommand('auto_mode');
    } else {
      _isAutoMode = false;
      _currentMode = 'manual';
      firebaseMode = 'manual';
      sendCommand('manual_mode');
    }

    // Update Firebase with the new mode
    FirebaseService().updateRobotMode(firebaseMode);

    // Notify listeners about the mode change via the message controller
    _messageController.add({
      'status': 'local_update',
      'mode': _currentMode,
      'isAutoMode': _isAutoMode,
    });
  }

  // Toggle auto mode - improved version that works more reliably
  Future<void> toggleAutoMode() async {
    // Ensure connection before toggling
    // if (!_isConnected) {
    //   final connected = await connect();
    //   if (!connected) {
    //     LogService.error('Cannot toggle mode: Not connected to robot');
    //     return;
    //   }
    // }

    // Determine the target mode based on the current state
    final bool currentAutoMode = _isAutoMode;
    final targetMode =
        currentAutoMode ? ModeCommand.manualMode : ModeCommand.autoMode;

    LogService.info(
      'Toggling mode from ${currentAutoMode ? "auto" : "manual"} to ${!currentAutoMode ? "auto" : "manual"}',
    );

    // Send the command to change mode
    sendModeCommand(targetMode);

    LogService.info('Mode toggle requested: ${targetMode.value}');
  }

  // Send a power command
  void sendPowerCommand(PowerCommand command) {
    if (command == PowerCommand.powerOn) {
      _isPoweredOn = true;
    } else {
      _isPoweredOn = false;
    }
    sendCommand(command.value);
  }

  // Reset bin to original position
  void resetBin() {
    LogService.info('Resetting bin to original position');
    sendActionCommand(ActionCommand.resetBin);

    // Update bin status to indicate reset
    _binStatus = 0; // 0 = original position
  }

  // Mark bin as clean (all trash collected)
  void cleanBin() {
    LogService.info('Marking bin as clean - all trash collected');
    sendActionCommand(ActionCommand.cleanBin);

    // Update bin status to indicate clean
    _binStatus = 0; // Reset to 0 after cleaning
  }

  // Set speed
  void setSpeed(int newSpeed) {
    _speed = newSpeed.clamp(0, 100);
    send({'speed': _speed});
    LogService.info('Speed set to: $_speed%');
  }

  // Toggle power
  void togglePower() {
    _isPoweredOn = !_isPoweredOn;
    send({'isPoweredOn': _isPoweredOn});
    sendPowerCommand(
      _isPoweredOn ? PowerCommand.powerOn : PowerCommand.powerOff,
    );
  }

  // Test connection with connect command
  Future<bool> testConnection() async {
    try {
      final wasConnected = _isConnected;
      if (!wasConnected) {
        LogService.info('Testing new connection...');
        final result = await connect();
        return result;
      } else {
        // Test existing connection with a connect command
        LogService.info('Testing existing connection...');
        final testData = {'direction': 'connect', 'speed': _speed};
        send(testData);
        return true;
      }
    } catch (e) {
      LogService.error('Connection test failed', e);
      return false;
    }
  }

  // Reconnect method with improved debugging
  Future<bool> reconnect() async {
    LogService.info('Force reconnecting WebSocket...');
    disconnect();
    _reconnectAttempt = 0; // Reset reconnect attempts

    // Ensure we wait a bit before reconnecting to allow previous connection to fully close
    await Future.delayed(const Duration(milliseconds: 500));

    final result = await connect();
    LogService.info('Reconnection result: ${result ? "Connected" : "Failed"}');
    return result;
  }

  // Dispose resources - modified to be safer for singleton pattern
  void dispose() {
    LogService.info('Disposing WebSocketService...');
    _isDisposed = true;

    disconnect();

    // Close stream controllers safely
    if (!_messageController.isClosed) {
      _messageController.close();
    }
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.close();
    }

    // Don't reset _instance in singleton since we want to keep reference
    // _instance = null;

    LogService.info('WebSocketService disposed');
  }
}
