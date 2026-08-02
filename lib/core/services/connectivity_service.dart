import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();
  
  static final StreamController<bool> _connectionChangeController = 
      StreamController<bool>.broadcast();

  static Stream<bool> get connectionStream => _connectionChangeController.stream;

  static bool _lastKnownStatus = true;
  static bool get isOnline => _lastKnownStatus;

  static void initialize() {
    // Initial check
    checkConnection().then((status) {
      _lastKnownStatus = status;
      _connectionChangeController.add(status);
    });

    // Listen for updates
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      if (hasConnection != _lastKnownStatus) {
        _lastKnownStatus = hasConnection;
        _connectionChangeController.add(hasConnection);
      }
    });
  }

  static Future<bool> checkConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any((result) => result != ConnectivityResult.none);
      _lastKnownStatus = hasConnection;
      return hasConnection;
    } catch (_) {
      return false;
    }
  }
}
