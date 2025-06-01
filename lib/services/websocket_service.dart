import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/subjects.dart';

import '../config/env_config.dart';
import '../constants/command_types.dart';
import 'log_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  // Stream controllers
  final _messageController = BehaviorSubject<dynamic>();
  final _connectionStatusController = BehaviorSubject<bool>.seeded(false);

  // Robot state
  bool _isPoweredOn = true;
  bool _isAutoMode = false;
  int _speed = 50;
  int _binStatus = 0;

  // Getters
  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  bool get isConnected => _isConnected;
  bool get isPoweredOn => _isPoweredOn;
  bool get isAutoMode => _isAutoMode;
  int get speed => _speed;
  int get binStatus => _binStatus;

  // Connect to WebSocket server
  Future<bool> connect() async {
    if (_isConnected) {
      LogService.info('Already connected to WebSocket server');
      return true;
    }

    // Clear any existing reconnect timer
    _reconnectTimer?.cancel();

    try {
      LogService.info('Connecting to WebSocket server: ${EnvConfig.wsUrl}');

      _channel = WebSocketChannel.connect(Uri.parse(EnvConfig.wsUrl));

      // Listen for messages
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          LogService.info('WebSocket connection closed');
          _handleDisconnection();
        },
        onError: (error) {
          LogService.error('WebSocket error', error);
          _handleDisconnection();
        },
      );

      // Wait for a brief moment to ensure connection is established
      await Future.delayed(const Duration(milliseconds: 100));

      // Update connection status
      _isConnected = true;
      _connectionStatusController.add(_isConnected);
      _reconnectAttempt = 0;

      LogService.info('Connected to WebSocket server');
      return true;
    } catch (e) {
      LogService.error('Failed to connect to WebSocket server', e);
      _handleDisconnection();
      return false;
    }
  }

  // Disconnect from WebSocket server
  void disconnect() {
    _reconnectTimer?.cancel();
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
    _connectionStatusController.add(false);
    LogService.info('Disconnected from WebSocket server');
  }

  // Handle reconnection on disconnect
  void _handleDisconnection() {
    _isConnected = false;
    _connectionStatusController.add(false);
    LogService.info('Disconnected from WebSocket server');

    // Schedule reconnect with exponential backoff
    _reconnectAttempt++;

    // Calculate backoff delay with jitter
    final baseDelay = 1000; // Start with 1 second
    final backoffFactor = 1.5;
    final maxReconnectDelay = 30000; // 30 seconds

    // Calculate delay: base * (1.5 ^ attempt) + random jitter
    final backoffDelay = baseDelay * (backoffFactor * _reconnectAttempt);
    final jitter = (DateTime.now().millisecondsSinceEpoch % 1000);
    final delay = (backoffDelay + jitter).clamp(0, maxReconnectDelay).toInt();

    LogService.info('Attempting to reconnect ($_reconnectAttempt/5)');

    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (_reconnectAttempt <= 5) {
        connect();
      } else {
        LogService.error('Max reconnection attempts reached');
      }
    });
  }

  // Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      LogService.info('Message from server: $message');

      // Parse the message
      if (message is String) {
        final data = jsonDecode(message);
        _messageController.add(data);

        // Update robot state based on received data
        if (data is Map) {
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
        }
      } else {
        _messageController.add(message);
      }
    } catch (e) {
      LogService.error('Error parsing WebSocket message', e);
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
    final data = {'direction': command, 'speed': _speed};
    LogService.info('Sending WS command: $data');
    send(data);
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
    if (command == ModeCommand.autoMode) {
      _isAutoMode = true;
    } else {
      _isAutoMode = false;
    }
    sendCommand(command.value);
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

  // Set speed
  void setSpeed(int newSpeed) {
    _speed = newSpeed.clamp(0, 100);
    send({'speed': _speed});
  }

  // Toggle auto mode
  void toggleAutoMode() {
    _isAutoMode = !_isAutoMode;
    send({'isAutoMode': _isAutoMode});
    sendModeCommand(
      _isAutoMode ? ModeCommand.autoMode : ModeCommand.manualMode,
    );
  }

  // Toggle power
  void togglePower() {
    _isPoweredOn = !_isPoweredOn;
    send({'isPoweredOn': _isPoweredOn});
    sendPowerCommand(
      _isPoweredOn ? PowerCommand.powerOn : PowerCommand.powerOff,
    );
  }

  // Test connection
  Future<bool> testConnection() async {
    final wasConnected = _isConnected;
    if (!wasConnected) {
      final result = await connect();
      if (result) {
        // Send a test message
        send({'test': true});
        return true;
      }
      return false;
    }
    // Already connected
    send({'test': true});
    return true;
  }

  // Dispose resources
  void dispose() {
    _reconnectTimer?.cancel();
    disconnect();
    _messageController.close();
    _connectionStatusController.close();
  }
}
