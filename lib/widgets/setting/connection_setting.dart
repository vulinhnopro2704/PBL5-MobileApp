import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class ConnectionSetting extends StatelessWidget {
  final TextEditingController hostController;
  final TextEditingController portController;
  final String hostLabel;
  final String portLabel;
  final bool isTesting;
  final String testResult;
  final VoidCallback onTestPressed;
  final String testButtonLabel;
  final IconData testIcon;

  const ConnectionSetting({
    super.key,
    required this.hostController,
    required this.portController,
    required this.hostLabel,
    required this.portLabel,
    required this.isTesting,
    required this.testResult,
    required this.onTestPressed,
    required this.testButtonLabel,
    this.testIcon = Icons.speed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Host Field
        TextFormField(
          controller: hostController,
          decoration: InputDecoration(
            labelText: hostLabel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            filled: true,
            fillColor: AppTheme.surfaceDark.withOpacity(0.7),
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.computer, color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $hostLabel';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Port Field
        TextFormField(
          controller: portController,
          decoration: InputDecoration(
            labelText: portLabel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white30),
            ),
            filled: true,
            fillColor: AppTheme.surfaceDark.withOpacity(0.7),
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.pin, color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter $portLabel';
            }
            final port = int.tryParse(value);
            if (port == null || port <= 0 || port > 65535) {
              return 'Please enter a valid port number (1-65535)';
            }
            return null;
          },
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        // Test Connection Button and Result
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isTesting ? null : onTestPressed,
                icon: Icon(testIcon),
                label: Text(isTesting ? 'Testing...' : testButtonLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: ConnectionTestResult(testResult: testResult)),
          ],
        ),
      ],
    );
  }
}

class ConnectionTestResult extends StatelessWidget {
  final String testResult;

  const ConnectionTestResult({super.key, required this.testResult});

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = testResult.contains('successful');
    final bool isError =
        testResult.contains('failed') || testResult.contains('Error');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isSuccess
                ? AppTheme.connectedColor.withOpacity(0.2)
                : isError
                ? AppTheme.disconnectedColor.withOpacity(0.2)
                : Colors.grey.shade800.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isSuccess
                  ? AppTheme.connectedColor
                  : isError
                  ? AppTheme.disconnectedColor
                  : Colors.grey.shade600,
          width: 1,
        ),
      ),
      child: Text(
        testResult.isEmpty ? 'Not tested' : testResult,
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
