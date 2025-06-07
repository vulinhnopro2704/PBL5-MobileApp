import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service for logging throughout the app
class LogService {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    level: kDebugMode ? Level.verbose : Level.info,
  );

  // Also create a simple console logger for direct output
  static void _consoleLog(String message) {
    // ignore: avoid_print
    print('📱 LOG: $message');
  }

  /// Log debug message with any type of data
  static void debug(String message, [dynamic data]) {
    // Convert data to string representation for simpler logging
    String dataStr = '';
    if (data != null) {
      if (data is Map) {
        dataStr = data.entries
            .map((e) => '${e.key}: ${_formatValue(e.value)}')
            .join(', ');
      } else if (data is List) {
        dataStr = data.map((item) => _formatValue(item)).join(', ');
      } else {
        dataStr = _formatValue(data);
      }
    }

    String logMessage = message;
    if (dataStr.isNotEmpty) {
      logMessage += ' | Data: $dataStr';
    }

    _logger.d(logMessage);
    if (kDebugMode) _consoleLog('DEBUG: $logMessage');
  }

  // Helper to format values for logging
  static String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is Map) {
      return '{${value.entries.map((e) => '${e.key}: ${_formatValue(e.value)}').join(', ')}}';
    }
    if (value is List) {
      return '[${value.map(_formatValue).join(', ')}]';
    }
    return value.toString();
  }

  /// Log info message
  static void info(String message) {
    _logger.i(message);
    if (kDebugMode) _consoleLog('INFO: $message');
  }

  /// Log warning message
  static void warning(String message) {
    _logger.w(message);
    if (kDebugMode) _consoleLog('WARN: $message');
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    if (kDebugMode) _consoleLog('ERROR: $message ${error ?? ''}');
  }
}
