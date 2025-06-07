import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import 'log_service.dart';

class AiService {
  // Update the detect objects method to accept an image URL
  Future<Map<String, dynamic>?> detectObjects({String? imageUrl}) async {
    try {
      if (imageUrl == null) {
        LogService.warning('No image URL provided for object detection');
        return null;
      }

      final baseUrl = '${EnvConfig.aiServerHost}:${EnvConfig.aiServerPort}';
      final uri = Uri.parse('$baseUrl/detect');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': imageUrl}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LogService.info(
          'Object detection successful: ${data['objects']?.length ?? 0} objects found',
        );
        return data;
      } else {
        LogService.error(
          'Object detection failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      LogService.error('Error detecting objects', e);
      return null;
    }
  }

  // Test connection to the AI server
  Future<bool> testAiServerConnection(String host, int port) async {
    try {
      final response = await http
          .get(Uri.parse('http://$host:$port/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      LogService.error('AI server test connection error', e);
      return false;
    }
  }
}
