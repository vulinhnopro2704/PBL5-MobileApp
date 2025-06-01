import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:rxdart/rxdart.dart';

import '../config/env_config.dart';
import 'log_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  // Stream controllers
  final _messageController = BehaviorSubject<dynamic>();
  final _connectionStatusController = BehaviorSubject<bool>.seeded(false);

  // Stream getters
  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  // Connection status
  bool get isConnected => _isConnected;

  // Connect to WebSocket server
  Future<bool> connect() async {
    if (_isConnected) {
      return true;
    }

    LogService.info('Connecting to WebSocket server: ${EnvConfig.wsUrl}');

    try {
      _channel = WebSocketChannel.connect(Uri.parse(EnvConfig.wsUrl));

      // Listen to incoming messages
      _channel!.stream.listen(
        (message) {
          _messageController.add(message);
          _resetReconnectAttempts();
        },
        onError: (error) {
          LogService.error('WebSocket error', error);
          _handleDisconnection();
        },
        onDone: () {
          LogService.info('WebSocket connection closed');
          _handleDisconnection();
        },
      );

      // Set connected status
      _isConnected = true;
      _connectionStatusController.add(true);
      _resetReconnectAttempts();

      // Start ping timer to keep connection alive
      _startPingTimer();

      return true;
    } catch (e) {
      LogService.error('Failed to connect to WebSocket server', e);
      _isConnected = false;
      _connectionStatusController.add(false);
      return false;
    }
  }

  // Disconnect from WebSocket server
  void disconnect() {
    _stopPingTimer();
    _stopReconnectTimer();

    if (_channel != null) {
      _channel!.sink.close(status.goingAway);
      _channel = null;
    }

    _isConnected = false;
    _connectionStatusController.add(false);
    LogService.info('Disconnected from WebSocket server');
  }

  // Send message to server
  void send(dynamic message) {
    if (!_isConnected) {
      LogService.warning('Attempted to send message while disconnected');
      return;
    }

    if (message is Map) {
      _channel!.sink.add(jsonEncode(message));
    } else {
      _channel!.sink.add(message.toString());
    }
  }

  // Test connection to server
  Future<bool> testConnection() async {
    final completer = Completer<bool>();

    // If already connected, just return true
    if (_isConnected) {
      return true;
    }

    try {
      final testChannel = WebSocketChannel.connect(Uri.parse(EnvConfig.wsUrl));

      // Set a timeout
      final timer = Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          testChannel.sink.close();
          completer.complete(false);
        }
      });

      // Listen for connection establishment
      testChannel.stream.listen(
        (message) {
          timer.cancel();
          testChannel.sink.close();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onError: (error) {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
        onDone: () {
          timer.cancel();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      // Send a test message
      testChannel.sink.add(jsonEncode({'type': 'ping'}));

      return completer.future;
    } catch (e) {
      LogService.error('Test connection error', e);
      return false;
    }
  }

  // Handle disconnection and auto-reconnect
  void _handleDisconnection() {
    if (!_isConnected) return;

    _isConnected = false;
    _connectionStatusController.add(false);
    _stopPingTimer();

    // Attempt to reconnect
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _startReconnectTimer();
    } else {
      LogService.warning('Max reconnect attempts reached');
    }
  }

  // Start ping timer to keep connection alive
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        send({'type': 'ping'});
      } else {
        _stopPingTimer();
      }
    });
  }

  // Stop ping timer
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  // Start reconnect timer
  void _startReconnectTimer() {
    _stopReconnectTimer();
    _reconnectAttempts++;

    LogService.info(
      'Attempting to reconnect ($_reconnectAttempts/$_maxReconnectAttempts)',
    );

    _reconnectTimer = Timer(_reconnectDelay, () async {
      final reconnected = await connect();
      if (!reconnected && _reconnectAttempts < _maxReconnectAttempts) {
        _startReconnectTimer();
      }
    });
  }

  // Stop reconnect timer
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // Reset reconnect attempts counter
  void _resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  // Clean up resources
  void dispose() {
    _stopPingTimer();
    _stopReconnectTimer();
    disconnect();
    _messageController.close();
    _connectionStatusController.close();
  }
}
