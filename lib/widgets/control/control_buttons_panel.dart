import 'package:flutter/material.dart';
import '../../widgets/control_button.dart';
import '../../config/app_theme.dart';
import '../../constants/command_types.dart';

class ControlButtonsPanel extends StatelessWidget {
  final Function(String) onSendCommand;
  final String? activeCommand;

  const ControlButtonsPanel({
    super.key,
    required this.onSendCommand,
    this.activeCommand,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            // Forward button
            GestureDetector(
              onTapDown: (_) => onSendCommand(DirectionCommand.forward.value),
              onTapUp: (_) => onSendCommand(DirectionCommand.stop.value),
              onTapCancel: () => onSendCommand(DirectionCommand.stop.value),
              child: ControlButton(
                icon: Icons.arrow_upward,
                label: 'Forward',
                onPressed:
                    () {}, // Empty because we're using the gesture detector
                color: AppTheme.forwardButtonColor,
                isPressed: activeCommand == DirectionCommand.forward.value,
              ),
            ),

            const SizedBox(height: 16),

            // Left, Down, Right buttons in a row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTapDown: (_) => onSendCommand(DirectionCommand.left.value),
                  onTapUp: (_) => onSendCommand(DirectionCommand.stop.value),
                  onTapCancel: () => onSendCommand(DirectionCommand.stop.value),
                  child: ControlButton(
                    icon: Icons.arrow_back,
                    label: 'Left',
                    onPressed:
                        () {}, // Empty because we're using the gesture detector
                    color: AppTheme.leftButtonColor,
                    isPressed: activeCommand == DirectionCommand.left.value,
                  ),
                ),
                const SizedBox(width: 32),
                GestureDetector(
                  onTapDown:
                      (_) => onSendCommand(DirectionCommand.backward.value),
                  onTapUp: (_) => onSendCommand(DirectionCommand.stop.value),
                  onTapCancel: () => onSendCommand(DirectionCommand.stop.value),
                  child: ControlButton(
                    icon: Icons.arrow_downward,
                    label: 'Backward',
                    onPressed:
                        () {}, // Empty because we're using the gesture detector
                    color: AppTheme.backwardButtonColor,
                    isPressed: activeCommand == DirectionCommand.backward.value,
                  ),
                ),
                const SizedBox(width: 32),
                GestureDetector(
                  onTapDown: (_) => onSendCommand(DirectionCommand.right.value),
                  onTapUp: (_) => onSendCommand(DirectionCommand.stop.value),
                  onTapCancel: () => onSendCommand(DirectionCommand.stop.value),
                  child: ControlButton(
                    icon: Icons.arrow_forward,
                    label: 'Right',
                    onPressed:
                        () {}, // Empty because we're using the gesture detector
                    color: AppTheme.rightButtonColor,
                    isPressed: activeCommand == DirectionCommand.right.value,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ControlButton(
                  icon: Icons.rotate_right,
                  label: 'Rotate Bin',
                  onPressed: () => onSendCommand(ActionCommand.rotateBin.value),
                  color: AppTheme.rotateButtonColor,
                ),
                const SizedBox(width: 24),
                ControlButton(
                  icon: Icons.pan_tool,
                  label: 'Grab Trash',
                  onPressed: () => onSendCommand(ActionCommand.grabTrash.value),
                  color: AppTheme.grabButtonColor,
                  isLarge: true,
                  isGlowing: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
