import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class SpeedSetting extends StatelessWidget {
  final double robotSpeed;
  final ValueChanged<double> onSpeedChanged;

  const SpeedSetting({
    super.key,
    required this.robotSpeed,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Speed information
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Speed:', style: AppTheme.bodyStyle),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getSpeedColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(robotSpeed * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        // Speed slider
        Slider(
          value: robotSpeed,
          onChanged: onSpeedChanged,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          label: '${(robotSpeed * 100).toInt()}%',
          activeColor: _getSpeedColor(),
        ),

        // Speed description
        Text(
          _getSpeedDescription(),
          style: const TextStyle(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Helper methods for speed settings
  Color _getSpeedColor() {
    if (robotSpeed < 0.3) {
      return Colors.green;
    } else if (robotSpeed < 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getSpeedDescription() {
    if (robotSpeed < 0.3) {
      return 'Safe speed for precision movement';
    } else if (robotSpeed < 0.7) {
      return 'Balanced speed for normal operation';
    } else {
      return 'High speed - use with caution!';
    }
  }
}
