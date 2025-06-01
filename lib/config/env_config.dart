import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  // API settings
  static String get apiHost => dotenv.env['API_HOST'] ?? 'localhost';
  static String get apiPort => dotenv.env['API_PORT'] ?? '8000';
  static String get apiBaseUrl => 'http://$apiHost:$apiPort';

  // WebSocket settings
  static String get wsHost => dotenv.env['WS_HOST'] ?? 'localhost';
  static String get wsPort => dotenv.env['WS_PORT'] ?? '8080';
  static String get wsUrl => 'ws://$wsHost:$wsPort';

  // AI Server settings
  static String? get aiServerHost => dotenv.env['AI_SERVER_HOST'];
  static String? get aiServerPort => dotenv.env['AI_SERVER_PORT'];
  static String get aiServerUrl =>
      'http://${aiServerHost ?? 'localhost'}:${aiServerPort ?? '5000'}';

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
}
