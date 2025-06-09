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
        return 'forward';
      case DirectionCommand.backward:
        return 'backward';
      case DirectionCommand.left:
        return 'left';
      case DirectionCommand.right:
        return 'right';
      case DirectionCommand.stop:
        return 'stop';
    }
  }
}

/// Action commands for robot operations
enum ActionCommand {
  grabTrash,
  rotateBin,
  takePicture,
  resetBin,
  cleanBin;

  String get value {
    switch (this) {
      case ActionCommand.grabTrash:
        return 'grab_trash';
      case ActionCommand.rotateBin:
        return 'rotate_bin';
      case ActionCommand.takePicture:
        return 'take_picture';
      case ActionCommand.resetBin:
        return 'reset_bin';
      case ActionCommand.cleanBin:
        return 'clean_bin';
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
        return 'auto_mode';
      case ModeCommand.manualMode:
        return 'manual_mode';
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
        return 'power_on';
      case PowerCommand.powerOff:
        return 'power_off';
    }
  }
}

/// Create speed command string
String getSpeedCommand(int speed) {
  return 'SPEED_$speed';
}

/// Add Camera Command type if not already present
enum CameraCommand { takePicture, detectObjects }

extension CameraCommandExtension on CameraCommand {
  String get value {
    switch (this) {
      case CameraCommand.takePicture:
        return 'take_picture';
      case CameraCommand.detectObjects:
        return 'detect_objects';
    }
  }
}
