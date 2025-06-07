import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class RobotModeSetting extends StatelessWidget {
  final bool isPoweredOn;
  final bool isAutoMode;
  final Function(bool) onPowerToggle;
  final Function(bool) onModeToggle;

  const RobotModeSetting({
    super.key,
    required this.isPoweredOn,
    required this.isAutoMode,
    required this.onPowerToggle,
    required this.onModeToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Power Status
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Power Status:', style: AppTheme.bodyStyle),
            Switch(
              value: isPoweredOn,
              onChanged: onPowerToggle,
              activeColor: AppTheme.accentColor,
              activeTrackColor: AppTheme.accentColor.withOpacity(0.5),
            ),
          ],
        ),

        // Auto/Manual Mode
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Operation Mode:', style: AppTheme.bodyStyle),
            Row(
              children: [
                Text(
                  'Manual',
                  style: TextStyle(
                    color: !isAutoMode ? Colors.white : Colors.white60,
                    fontWeight:
                        !isAutoMode ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                Switch(
                  value: isAutoMode,
                  onChanged: onModeToggle,
                  activeColor: AppTheme.accentColor,
                  activeTrackColor: AppTheme.accentColor.withOpacity(0.5),
                ),
                Text(
                  'Auto',
                  style: TextStyle(
                    color: isAutoMode ? Colors.white : Colors.white60,
                    fontWeight:
                        isAutoMode ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Mode explanation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            isAutoMode
                ? 'Auto Mode: The robot will navigate and collect trash autonomously.'
                : 'Manual Mode: You have full control over the robot movement and actions.',
            style: const TextStyle(
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
