import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class SettingCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SettingCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.subheadingStyle),
            ],
          ),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
