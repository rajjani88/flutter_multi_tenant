import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final isOnlineStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.isOnlineStream;
});

class DegradedModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setMode(bool val) {
    state = val;
  }
}

final degradedModeProvider =
    NotifierProvider<DegradedModeNotifier, bool>(() => DegradedModeNotifier());
