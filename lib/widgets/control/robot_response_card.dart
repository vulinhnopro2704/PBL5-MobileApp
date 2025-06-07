import 'dart:convert';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class RobotResponseCard extends StatelessWidget {
  final Map<String, dynamic> response;

  const RobotResponseCard({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getResponseStatusColor(response),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getResponseStatusIcon(response),
                color: _getResponseStatusColor(response),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Robot Response',
                style: AppTheme.subheadingStyle.copyWith(fontSize: 14),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 16),
          _buildResponseDetails(response),
        ],
      ),
    );
  }

  // Helper method to build response details based on the response type
  Widget _buildResponseDetails(Map<String, dynamic> response) {
    final status = response['status'] as String?;
    final action = response['action'] as String?;
    final direction = response['direction'] as String?;
    final message = response['message'] as String?;
    final speed = response['speed'] as int?;
    final currentBin = response['current_bin'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (status != null)
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70),
              children: [
                const TextSpan(
                  text: 'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: status,
                  style: TextStyle(
                    color:
                        status.toLowerCase() == 'success'
                            ? Colors.green
                            : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (action != null) ...[
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70),
              children: [
                const TextSpan(
                  text: 'Action: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: _formatActionName(action)),
              ],
            ),
          ),
        ],
        if (direction != null) ...[
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70),
              children: [
                const TextSpan(
                  text: 'Direction: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: direction),
              ],
            ),
          ),
        ],
        if (speed != null) ...[
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70),
              children: [
                const TextSpan(
                  text: 'Speed: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '$speed%'),
              ],
            ),
          ),
        ],
        if (currentBin != null) ...[
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70),
              children: [
                const TextSpan(
                  text: 'Current Bin: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '$currentBin'),
              ],
            ),
          ),
        ],
        if (message != null) ...[
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white70),
              children: [
                const TextSpan(
                  text: 'Message: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: message),
              ],
            ),
          ),
        ],
        // Display any additional response data if available
        if (response.containsKey('response') &&
            response['response'] is Map) ...[
          const SizedBox(height: 8),
          const Text(
            'Additional Response Data:',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
            constraints: const BoxConstraints(maxHeight: 100),
            child: SingleChildScrollView(
              child: Text(
                _formatJsonString(response['response']),
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Format action names to be more readable
  String _formatActionName(String action) {
    // Convert snake_case to Title Case
    return action
        .split('_')
        .map((word) {
          return word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '';
        })
        .join(' ');
  }

  // Format JSON for display
  String _formatJsonString(dynamic json) {
    const encoder = JsonEncoder.withIndent('  ');
    try {
      return encoder.convert(json);
    } catch (e) {
      return json.toString();
    }
  }

  // Helper method to get response status color
  Color _getResponseStatusColor(Map<String, dynamic> response) {
    final status = response['status'] as String?;

    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  // Helper method to get response status icon
  IconData _getResponseStatusIcon(Map<String, dynamic> response) {
    final status = response['status'] as String?;

    if (status == null) return Icons.info_outline;

    switch (status.toLowerCase()) {
      case 'success':
        return Icons.check_circle_outline;
      case 'error':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }
}
