import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class ModeToggleButton extends StatelessWidget {
  final bool isAutoMode;
  final bool isPoweredOn;
  final VoidCallback onModeToggle;
  final VoidCallback onPowerToggle;

  const ModeToggleButton({
    super.key,
    required this.isAutoMode,
    required this.isPoweredOn,
    required this.onModeToggle,
    required this.onPowerToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(
            isAutoMode ? Icons.auto_mode : Icons.handyman,
            color: isAutoMode ? AppTheme.accentColor : Colors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Robot Mode',
                  style: AppTheme.subheadingStyle.copyWith(fontSize: 14),
                ),
                Text(
                  isAutoMode ? 'Auto Mode' : 'Manual Mode',
                  style: AppTheme.bodyStyle.copyWith(
                    color: isAutoMode ? AppTheme.accentColor : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isAutoMode,
            activeColor: AppTheme.accentColor,
            activeTrackColor: AppTheme.accentColor.withOpacity(0.5),
            onChanged: (_) => onModeToggle(),
          ),
          // const SizedBox(width: 8),
          // IconButton(
          //   icon: Icon(
          //     isPoweredOn ? Icons.power_settings_new : Icons.power_off,
          //     color: isPoweredOn ? Colors.green : Colors.red,
          //   ),
          //   onPressed: onPowerToggle,
          //   tooltip: isPoweredOn ? 'Power Off' : 'Power On',
          // ),
        ],
      ),
    );
  }
}
