import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import 'log_service.dart';

class ApiService {
  late final Dio _dio;

  ApiService() {
    // Initialize with safe default URL if environment isn't loaded
    final baseUrl =
        EnvConfig.isInitialized
            ? EnvConfig.apiBaseUrl
            : 'http://localhost:8000';

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
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

  // Capture image from the robot's camera
  Future<String?> captureImage() async {
    try {
      final url = '${EnvConfig.apiBaseUrl}/camera/capture';
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['image_url'];

        // Add to history if history service is available - commented for now
        // if (imageUrl != null) {
        //   await recordImageCapture(imageUrl);
        // }

        return imageUrl;
      }
      return null;
    } catch (e) {
      LogService.error('Error capturing image', e);
      return null;
    }
  }

  // Run object detection on the captured image
  Future<Map<String, dynamic>?> detectObjects() async {
    try {
      final url = '${EnvConfig.aiServerUrl}/detect';
      final response = await http.post(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Add to history if possible - commented for now
        // await recordObjectDetection(data);

        return data;
      }
      return null;
    } catch (e) {
      LogService.error('Error detecting objects', e);
      return null;
    }
  }

  // Record image capture event in history - will implement later
  Future<void> recordImageCapture(String imageUrl) async {
    try {
      // This is a placeholder for now to avoid the unused variable warning
      LogService.info('Image captured: $imageUrl');
      // Will implement with history service later
    } catch (e) {
      LogService.error('Error recording image capture', e);
    }
  }

  // Record object detection event in history - will implement later
  Future<void> recordObjectDetection(Map<String, dynamic> detectionData) async {
    try {
      // This is a placeholder for now to avoid the unused variable warning
      LogService.info(
        'Detection data recorded: ${detectionData.length} objects',
      );
      // Will implement with history service later
    } catch (e) {
      LogService.error('Error recording object detection', e);
    }
  }

  // Record trash grab event
  Future<bool> recordTrashGrab({
    required bool success,
    String? imageUrl,
    String? description,
  }) async {
    try {
      // Log for now to avoid unused variable warnings
      LogService.info(
        'Trash grab recorded: success=$success, imageUrl=$imageUrl, description=$description',
      );
      return true;
    } catch (e) {
      LogService.error('Error recording trash grab', e);
      return false;
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
}
