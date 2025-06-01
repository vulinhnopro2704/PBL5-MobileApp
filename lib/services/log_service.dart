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

  /// Log debug message
  static void debug(String message) {
    _logger.d(message);
    if (kDebugMode) _consoleLog('DEBUG: $message');
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
