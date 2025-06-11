import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class ConnectionStatusCard extends StatelessWidget {
  final bool isConnected;
  final bool isConnecting;
  final String status;
  final VoidCallback onReconnect;

  const ConnectionStatusCard({
    super.key,
    required this.isConnected,
    required this.isConnecting,
    required this.status,
    required this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          isConnecting
              ? SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.connectingColor,
                  ),
                  strokeWidth: 3,
                ),
              )
              : Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color:
                    isConnected
                        ? AppTheme.connectedColor
                        : AppTheme.disconnectedColor,
                size: 32,
              ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connection Status', style: AppTheme.subheadingStyle),
                Text(status, style: AppTheme.bodyStyle),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: isConnecting ? null : onReconnect,
            icon: const Icon(Icons.refresh),
            label: Text(
              isConnecting ? 'Connecting...' : 'Reconnect',
              style: AppTheme.buttonTextStyle,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isConnected ? Colors.grey : AppTheme.primaryColor,
              disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
