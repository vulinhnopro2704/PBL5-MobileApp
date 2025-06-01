import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_item.dart';
import '../config/env_config.dart';
import 'log_service.dart';

class HistoryService {
  static const String _localHistoryKey = 'robot_history';

  // Fetch history from server or local storage
  Future<List<HistoryItem>> getHistory() async {
    try {
      // Try to fetch from server first
      final serverHistory = await _fetchHistoryFromServer();
      if (serverHistory.isNotEmpty) {
        // Cache the results locally
        _saveHistoryLocally(serverHistory);
        return serverHistory;
      }

      // Fall back to local cache if server fetch fails
      return await _fetchHistoryFromLocal();
    } catch (e) {
      LogService.error('Error fetching history', e);
      // Try local storage as fallback
      return await _fetchHistoryFromLocal();
    }
  }

  // Add a new history item
  Future<bool> addHistoryItem(HistoryItem item) async {
    try {
      // Try to save to server
      final success = await _addHistoryItemToServer(item);

      if (success) {
        // Also update local cache
        final history = await _fetchHistoryFromLocal();
        history.insert(0, item); // Add at beginning
        _saveHistoryLocally(history);
      }

      return success;
    } catch (e) {
      LogService.error('Error adding history item', e);
      return false;
    }
  }

  // Clear history
  Future<bool> clearHistory() async {
    try {
      // Clear from server
      final success = await _clearHistoryFromServer();

      if (success) {
        // Also clear local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_localHistoryKey);
      }

      return success;
    } catch (e) {
      LogService.error('Error clearing history', e);
      return false;
    }
  }

  // Private method to fetch history from server
  Future<List<HistoryItem>> _fetchHistoryFromServer() async {
    try {
      final response = await http
          .get(Uri.parse('${EnvConfig.apiBaseUrl}/history'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => HistoryItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      LogService.error('Server history fetch failed', e);
      return [];
    }
  }

  // Private method to fetch history from local storage
  Future<List<HistoryItem>> _fetchHistoryFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_localHistoryKey);

      if (historyJson != null) {
        final List<dynamic> data = jsonDecode(historyJson);
        return data.map((item) => HistoryItem.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      LogService.error('Local history fetch failed', e);
      return [];
    }
  }

  // Private method to save history to local storage
  Future<void> _saveHistoryLocally(List<HistoryItem> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convert history items to JSON
      final List<Map<String, dynamic>> historyJson =
          history
              .map(
                (item) => {
                  'id': item.id,
                  'timestamp': item.timestamp.toIso8601String(),
                  'event_type': item.eventType.toString().split('.').last,
                  'image_url': item.imageUrl,
                  'detection_data': item.detectionData,
                  'description': item.description,
                  'success': item.success,
                },
              )
              .toList();

      await prefs.setString(_localHistoryKey, jsonEncode(historyJson));
    } catch (e) {
      LogService.error('Failed to save history locally', e);
    }
  }

  // Private method to add history item to server
  Future<bool> _addHistoryItemToServer(HistoryItem item) async {
    try {
      final response = await http
          .post(
            Uri.parse('${EnvConfig.apiBaseUrl}/history'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'id': item.id,
              'timestamp': item.timestamp.toIso8601String(),
              'event_type': item.eventType.toString().split('.').last,
              'image_url': item.imageUrl,
              'detection_data': item.detectionData,
              'description': item.description,
              'success': item.success,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      LogService.error('Failed to add history item to server', e);
      return false;
    }
  }

  // Private method to clear history from server
  Future<bool> _clearHistoryFromServer() async {
    try {
      final response = await http
          .delete(Uri.parse('${EnvConfig.apiBaseUrl}/history'))
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      LogService.error('Failed to clear server history', e);
      return false;
    }
  }
}
