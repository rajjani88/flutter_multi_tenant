import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _networkStatusController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  bool _isDegradedMode = false;
  int _simulatedLatencyMs = 0;

  bool get isOnline => _isOnline;
  bool get isDegradedMode => _isDegradedMode;
  int get simulatedLatencyMs => _simulatedLatencyMs;
  Stream<bool> get isOnlineStream => _networkStatusController.stream;

  ConnectivityService() {
    _init();
  }

  void _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);
    _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection =
        results.any((r) => r != ConnectivityResult.none);
    _isOnline = hasConnection;
    _networkStatusController.add(_isOnline);
  }

  /// Toggle simulated degraded network (Slow API latency) for demonstration
  void toggleDegradedMode(bool enabled, {int latencyMs = 2000}) {
    _isDegradedMode = enabled;
    _simulatedLatencyMs = enabled ? latencyMs : 0;
  }

  /// Introduce delay if degraded network mode is active
  Future<void> simulateLatencyIfNeeded() async {
    if (_isDegradedMode && _simulatedLatencyMs > 0) {
      await Future.delayed(Duration(milliseconds: _simulatedLatencyMs));
    }
  }

  void dispose() {
    _networkStatusController.close();
  }
}
