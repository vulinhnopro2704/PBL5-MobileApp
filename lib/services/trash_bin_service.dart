import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

import '../models/trash_bin_model.dart';
import 'log_service.dart';

class TrashBinService {
  static final TrashBinService _instance = TrashBinService._internal();
  factory TrashBinService() => _instance;
  TrashBinService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  DatabaseReference? _trashBinRef; // Changed from late to nullable
  StreamSubscription<DatabaseEvent>? _subscription;

  StreamController<TrashBinData>? _dataController;
  bool _isInitialized = false;
  bool _isDisposed = false;

  Stream<TrashBinData> get dataStream {
    if (_dataController == null || _dataController!.isClosed) {
      _dataController = StreamController<TrashBinData>.broadcast();
    }
    return _dataController!.stream;
  }

  void initialize() {
    if (_isDisposed) {
      _isDisposed = false;
    }

    if (_dataController == null || _dataController!.isClosed) {
      _dataController = StreamController<TrashBinData>.broadcast();
    }

    try {
      // Only initialize _trashBinRef if it hasn't been initialized yet
      _trashBinRef ??= _database.ref('trash_bin');
      _startListening();
      _isInitialized = true;
      LogService.info('TrashBinService initialized');
    } catch (e) {
      LogService.error('Failed to initialize TrashBinService', e);
    }
  }

  void _startListening() {
    _subscription?.cancel();

    if (_trashBinRef == null) return;

    _subscription = _trashBinRef!.onValue.listen(
      (DatabaseEvent event) {
        // Multiple safety checks
        if (_isDisposed ||
            _dataController == null ||
            _dataController!.isClosed) {
          LogService.debug(
            'Skipping data update - service disposed or controller closed',
          );
          return;
        }

        try {
          final data = event.snapshot.value;
          if (data != null && data is Map) {
            final trashBinData = TrashBinData.fromMap(
              Map<String, dynamic>.from(data),
            );

            // Final check before adding to stream
            if (!_isDisposed &&
                _dataController != null &&
                !_dataController!.isClosed) {
              _dataController!.add(trashBinData);
              LogService.info(
                'Trash bin data updated: ${trashBinData.toMap()}',
              );
            }
          } else {
            // Send empty data if no data exists
            if (!_isDisposed &&
                _dataController != null &&
                !_dataController!.isClosed) {
              _dataController!.add(
                TrashBinData(metal: 0, other: 0, paper: 0, plastic: 0),
              );
            }
          }
        } catch (e) {
          LogService.error('Error processing trash bin data', e);
          if (!_isDisposed &&
              _dataController != null &&
              !_dataController!.isClosed) {
            _dataController!.addError(e);
          }
        }
      },
      onError: (error) {
        LogService.error('Error listening to trash bin data', error);
        if (!_isDisposed &&
            _dataController != null &&
            !_dataController!.isClosed) {
          _dataController!.addError(error);
        }
      },
    );
  }

  Future<void> updateTrashBin(TrashBinData data) async {
    if (_isDisposed || _trashBinRef == null) {
      LogService.warning('Attempted to update trash bin on disposed service');
      return;
    }

    try {
      await _trashBinRef!.set(data.toMap());
      LogService.info('Trash bin data updated successfully');
    } catch (e) {
      LogService.error('Error updating trash bin data', e);
      rethrow;
    }
  }

  Future<void> resetTrashBin() async {
    if (_isDisposed || _trashBinRef == null) {
      LogService.warning('Attempted to reset trash bin on disposed service');
      return;
    }

    try {
      final emptyData = TrashBinData(metal: 0, other: 0, paper: 0, plastic: 0);
      await updateTrashBin(emptyData);
    } catch (e) {
      LogService.error('Error resetting trash bin', e);
      rethrow;
    }
  }

  void pause() {
    _subscription?.cancel();
    _subscription = null;
    LogService.info('TrashBinService paused');
  }

  void resume() {
    if (_isInitialized && !_isDisposed) {
      _startListening();
      LogService.info('TrashBinService resumed');
    }
  }

  void dispose() {
    LogService.info('Disposing TrashBinService...');
    _isDisposed = true;

    _subscription?.cancel();
    _subscription = null;

    _dataController?.close();
    _dataController = null;

    _isInitialized = false;
    _trashBinRef = null; // Reset the reference
    LogService.info('TrashBinService disposed');
  }

  bool get isInitialized => _isInitialized && !_isDisposed;
}
