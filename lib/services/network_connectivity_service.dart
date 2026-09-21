import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance =
      NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  static NetworkConnectivityService get instance => _instance;

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  VoidCallback? onConnectionRestored;

  /// Inisialisasi listener konektivitas jaringan
  Future<void> initialize({VoidCallback? onRestored}) async {
    onConnectionRestored = onRestored;
    final results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !isOnline.value;
      _updateStatus(results);

      if (wasOffline && isOnline.value) {
        debugPrint('[Connectivity] Internet kembali aktif. Memicu sinkronisasi...');
        onConnectionRestored?.call();
      }
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
    isOnline.value = hasConnection;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
