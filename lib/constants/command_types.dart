/// Command types for robot control
/// Provides type safety when sending commands
library;

/// Direction commands for robot movement
enum DirectionCommand {
  forward,
  backward,
  left,
  right,
  stop;

  String get value {
    switch (this) {
      case DirectionCommand.forward:
        return 'FORWARD';
      case DirectionCommand.backward:
        return 'BACKWARD';
      case DirectionCommand.left:
        return 'LEFT';
      case DirectionCommand.right:
        return 'RIGHT';
      case DirectionCommand.stop:
        return 'STOP';
    }
  }
}

/// Action commands for robot operations
enum ActionCommand {
  grabTrash,
  rotateBin,
  takePicture;

  String get value {
    switch (this) {
      case ActionCommand.grabTrash:
        return 'GRAB_TRASH';
      case ActionCommand.rotateBin:
        return 'ROTATE_BIN';
      case ActionCommand.takePicture:
        return 'TAKE_PICTURE';
    }
  }
}

/// Mode commands for robot operation mode
enum ModeCommand {
  autoMode,
  manualMode;

  String get value {
    switch (this) {
      case ModeCommand.autoMode:
        return 'AUTO_MODE';
      case ModeCommand.manualMode:
        return 'MANUAL_MODE';
    }
  }
}

/// Power commands for robot power state
enum PowerCommand {
  powerOn,
  powerOff;

  String get value {
    switch (this) {
      case PowerCommand.powerOn:
        return 'POWER_ON';
      case PowerCommand.powerOff:
        return 'POWER_OFF';
    }
  }
}

/// Create speed command string
String getSpeedCommand(int speed) {
  return 'SPEED_$speed';
}
