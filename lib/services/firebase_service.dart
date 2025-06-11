import 'package:firebase_database/firebase_database.dart';
import 'log_service.dart';

class FirebaseService {
  // Singleton instance
  static FirebaseService? _instance;
  static FirebaseService get instance {
    _instance ??= FirebaseService._internal();
    return _instance!;
  }

  FirebaseService._internal() {
    _database = FirebaseDatabase.instance;
  }

  factory FirebaseService() {
    return instance;
  }

  late FirebaseDatabase _database;

  // Update robot mode in Firebase
  Future<void> updateRobotMode(String mode) async {
    try {
      // Ensure we only save "manual" or "auto" in Firebase
      if (mode != 'auto' && mode != 'manual') {
        mode = mode.contains('auto') ? 'auto' : 'manual';
      }

      await _database.ref().update({'mode': mode});
      LogService.info('Updated Firebase mode: $mode');
    } catch (e) {
      LogService.error('Error updating Firebase mode', e);
    }
  }
}
