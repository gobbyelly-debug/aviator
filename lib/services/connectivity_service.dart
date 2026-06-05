import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  static final List<Uri> _internetProbeUris = [
    Uri.parse('https://clients3.google.com/generate_204'),
    Uri.parse('https://www.gstatic.com/generate_204'),
  ];

  /// Check whether the device has any active network path.
  /// This intentionally avoids external internet probes so local API setups work.
  Future<bool> hasNetworkConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      if (result.isEmpty || result.contains(ConnectivityResult.none)) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check whether the device can reach the public internet.
  Future<bool> hasInternetConnection() async {
    final hasNetwork = await hasNetworkConnection();
    if (!hasNetwork) {
      return false;
    }

    for (final uri in _internetProbeUris) {
      HttpClient? client;
      try {
        client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
        final request = await client
            .getUrl(uri)
            .timeout(const Duration(seconds: 4));
        request.headers.set(HttpHeaders.connectionHeader, 'close');
        final response = await request.close().timeout(
          const Duration(seconds: 4),
        );
        await response.drain<void>();

        if (response.statusCode >= 200 && response.statusCode < 400) {
          return true;
        }
      } on TimeoutException catch (_) {
      } on SocketException catch (_) {
      } catch (_) {
      } finally {
        client?.close(force: true);
      }
    }

    return false;
  }

  /// Get current connectivity status as a readable string
  Future<String> getConnectivityStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();

      if (result.isEmpty || result.contains(ConnectivityResult.none)) {
        return 'offline';
      } else if (result.contains(ConnectivityResult.mobile)) {
        return 'mobile';
      } else if (result.contains(ConnectivityResult.wifi)) {
        return 'wifi';
      } else if (result.contains(ConnectivityResult.ethernet)) {
        return 'ethernet';
      }
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }
}
