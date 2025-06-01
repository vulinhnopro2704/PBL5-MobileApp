import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/env_config.dart';
import '../services/log_service.dart';
import '../services/history_service.dart';
import '../models/history_item.dart';

class ApiService {
  late final Dio _dio;
  final HistoryService _historyService = HistoryService();
  final Uuid _uuid = const Uuid();

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );

    // Add interceptors for logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          LogService.info('API Request: ${options.method} ${options.uri}');
          LogService.debug('Request data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          LogService.info(
            'API Response: ${response.statusCode} ${response.requestOptions.uri}',
          );
          LogService.debug('Response data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          LogService.error(
            'API Error: ${e.response?.statusCode} ${e.requestOptions.uri}',
            e,
            e.stackTrace,
          );
          return handler.next(e);
        },
      ),
    );
  }

  // Set auth token
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } catch (e) {
      LogService.error('GET request failed: $path', e);
      rethrow;
    }
  }

  // POST request
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } catch (e) {
      LogService.error('POST request failed: $path', e);
      rethrow;
    }
  }

  // Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse('${EnvConfig.apiBaseUrl}/health'))
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      LogService.error('API test connection error', e);
      return false;
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

  // Capture image from the robot's camera
  Future<String?> captureImage() async {
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.apiBaseUrl}/camera/capture'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['image_url'];

        // Add to history
        if (imageUrl != null) {
          await _historyService.addHistoryItem(
            HistoryItem(
              id: _uuid.v4(),
              timestamp: DateTime.now(),
              eventType: HistoryEventType.imageCaptured,
              imageUrl: imageUrl,
              description: 'Image captured from robot camera',
              success: true,
            ),
          );
        }

        return imageUrl;
      }
      return null;
    } catch (e) {
      LogService.error('Error capturing image', e);

      // Add failed event to history
      await _historyService.addHistoryItem(
        HistoryItem(
          id: _uuid.v4(),
          timestamp: DateTime.now(),
          eventType: HistoryEventType.imageCaptured,
          description: 'Failed to capture image: ${e.toString()}',
          success: false,
        ),
      );

      return null;
    }
  }

  // Run object detection on the captured image
  Future<Map<String, dynamic>?> detectObjects() async {
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.aiServerUrl}/detect'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Add to history
        await _historyService.addHistoryItem(
          HistoryItem(
            id: _uuid.v4(),
            timestamp: DateTime.now(),
            eventType: HistoryEventType.objectDetected,
            imageUrl:
                data['image_url'], // If the response includes the processed image
            detectionData: data,
            description: _generateDetectionDescription(data),
            success: true,
          ),
        );

        return data;
      }
      return null;
    } catch (e) {
      LogService.error('Error detecting objects', e);

      // Add failed event to history
      await _historyService.addHistoryItem(
        HistoryItem(
          id: _uuid.v4(),
          timestamp: DateTime.now(),
          eventType: HistoryEventType.objectDetected,
          description: 'Failed to detect objects: ${e.toString()}',
          success: false,
        ),
      );

      return null;
    }
  }

  // Record trash grab event
  Future<bool> recordTrashGrab({
    required bool success,
    String? imageUrl,
    String? description,
  }) async {
    try {
      // Add to history
      await _historyService.addHistoryItem(
        HistoryItem(
          id: _uuid.v4(),
          timestamp: DateTime.now(),
          eventType: HistoryEventType.trashGrabbed,
          imageUrl: imageUrl,
          description:
              description ??
              (success ? 'Trash successfully grabbed' : 'Failed to grab trash'),
          success: success,
        ),
      );

      // Also record on server if available
      try {
        await http.post(
          Uri.parse('${EnvConfig.apiBaseUrl}/events/trash-grab'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'timestamp': DateTime.now().toIso8601String(),
            'success': success,
            'image_url': imageUrl,
            'description': description,
          }),
        );
      } catch (e) {
        // Only log the error but don't fail the operation
        LogService.error('Failed to record trash grab on server', e);
      }

      return true;
    } catch (e) {
      LogService.error('Error recording trash grab', e);
      return false;
    }
  }

  // Generate a human-readable description of the detection results
  String _generateDetectionDescription(Map<String, dynamic> detectionData) {
    if (!detectionData.containsKey('objects') ||
        detectionData['objects'] is! List ||
        (detectionData['objects'] as List).isEmpty) {
      return 'No objects detected in image';
    }

    final objects = List<Map<String, dynamic>>.from(detectionData['objects']);
    final objectCounts = <String, int>{};

    // Count objects by class
    for (final obj in objects) {
      final className = obj['class'] ?? 'Unknown';
      objectCounts[className] = (objectCounts[className] ?? 0) + 1;
    }

    // Generate description
    final buffer = StringBuffer('Detected ');
    buffer.write('${objects.length} object${objects.length > 1 ? 's' : ''}: ');

    final countDescriptions =
        objectCounts.entries
            .map((e) => '${e.value} ${e.key}${e.value > 1 ? 's' : ''}')
            .toList();

    buffer.write(countDescriptions.join(', '));

    return buffer.toString();
  }
}
