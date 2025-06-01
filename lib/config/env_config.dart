import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EnvConfig {
  // Store resolved IP for raspberrypi.local
  static String? _resolvedRaspberryPiIP;

  // API settings
  static String get apiHost => dotenv.env['API_HOST'] ?? 'localhost';
  static String get apiPort => dotenv.env['API_PORT'] ?? '8000';
  static String get apiBaseUrl => 'http://$apiHost:$apiPort';

  // WebSocket settings
  static String get wsHost => dotenv.env['WS_HOST'] ?? 'localhost';
  static String get wsPort => dotenv.env['WS_PORT'] ?? '8080';

  // Get WebSocket URL with fallback logic
  static String get wsUrl {
    final host = wsHost;
    final port = wsPort;

    // If WS_URL is directly specified, use that
    if (dotenv.env.containsKey('WS_URL')) {
      return dotenv.env['WS_URL']!;
    }

    // If using raspberrypi.local and we have a resolved IP, use it
    if (host == 'raspberrypi.local' && _resolvedRaspberryPiIP != null) {
      return 'ws://$_resolvedRaspberryPiIP:$port';
    }

    // Regular URL construction
    return 'ws://$host:$port';
  }

  // Store a resolved IP for raspberrypi.local
  static Future<void> setResolvedRaspberryPiIP(String ip) async {
    _resolvedRaspberryPiIP = ip;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('resolved_raspberrypi_ip', ip);
    } catch (e) {
      // Ignore errors when saving preference
    }
  }

  // Load previously resolved IP for raspberrypi.local
  static Future<void> loadResolvedRaspberryPiIP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _resolvedRaspberryPiIP = prefs.getString('resolved_raspberrypi_ip');
    } catch (e) {
      // Ignore errors when loading preference
    }
  }

  // AI Server settings
  static String get aiServerHost => dotenv.env['AI_SERVER_HOST'] ?? 'localhost';
  static String get aiServerPort => dotenv.env['AI_SERVER_PORT'] ?? '5000';
  static String get aiServerUrl => 'http://$aiServerHost:$aiServerPort';

  // Robot speed setting (0.1 to 1.0)
  static double? get robotSpeed {
    final speedStr = dotenv.env['ROBOT_SPEED'];
    if (speedStr == null) return 0.5; // Default speed

    try {
      final speed = double.parse(speedStr);
      return speed.clamp(0.1, 1.0);
    } catch (e) {
      return 0.5; // Default if parsing fails
    }
  }

  // Check if environment is properly loaded
  static bool get isInitialized {
    try {
      return dotenv.isInitialized && dotenv.env.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
