import 'package:flutter/material.dart';
import '../../widgets/control_button.dart';
import '../../config/app_theme.dart';
import '../../constants/command_types.dart';

class SimpleGrabButton extends StatelessWidget {
  final Function(String) onSendCommand;

  const SimpleGrabButton({super.key, required this.onSendCommand});

  @override
  Widget build(BuildContext context) {
    return ControlButton(
      icon: Icons.pan_tool,
      label: 'Grab',
      onPressed: () => onSendCommand(ActionCommand.grabTrash.value),
      color: AppTheme.grabButtonColor,
    );
  }
}
