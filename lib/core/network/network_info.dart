import 'dart:async';
import 'dart:io';

/// Network connection status
enum NetworkStatus { connected, disconnected, connecting, unknown }

/// Network connection quality
enum NetworkQuality { excellent, good, poor, offline }

/// Network connection information
class NetworkConnectionInfo {
  final NetworkStatus status;
  final NetworkQuality quality;
  final Duration? latency;
  final DateTime lastChecked;

  const NetworkConnectionInfo({
    required this.status,
    required this.quality,
    this.latency,
    required this.lastChecked,
  });

  bool get isConnected => status == NetworkStatus.connected;
  bool get isOffline => status == NetworkStatus.disconnected;
}

/// Abstract interface for network connectivity information
abstract class NetworkInfo {
  Future<bool> get isConnected;
  Stream<NetworkConnectionInfo> get onConnectivityChanged;
  Future<bool> hasInternetAccess();
  Future<NetworkConnectionInfo> getConnectionInfo();
  Future<Duration?> measureLatency();
  void startMonitoring();
  void stopMonitoring();
  void dispose();
}

/// Implementation of NetworkInfo using platform-specific checks
class NetworkInfoImpl implements NetworkInfo {
  static const String _primaryTestHost = 'google.com';
  static const String _fallbackTestHost = '8.8.8.8';
  static const int _testPort = 443;
  static const Duration _testTimeout = Duration(seconds: 5);
  static const Duration _latencyTimeout = Duration(seconds: 3);
  static const Duration _monitoringInterval = Duration(seconds: 5);

  final StreamController<NetworkConnectionInfo> _connectivityController =
      StreamController<NetworkConnectionInfo>.broadcast();
  Timer? _connectivityTimer;
  NetworkConnectionInfo _lastKnownInfo = NetworkConnectionInfo(
    status: NetworkStatus.unknown,
    quality: NetworkQuality.offline,
    lastChecked: DateTime.now(),
  );
  bool _isMonitoring = false;

  @override
  Future<bool> get isConnected async {
    final info = await getConnectionInfo();
    return info.isConnected;
  }

  @override
  Stream<NetworkConnectionInfo> get onConnectivityChanged {
    if (!_isMonitoring) {
      startMonitoring();
    }
    return _connectivityController.stream;
  }

  @override
  Future<bool> hasInternetAccess() async {
    try {
      // Try primary host first
      final result = await InternetAddress.lookup(
        _primaryTestHost,
      ).timeout(_testTimeout);

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      // Try fallback host
      try {
        final result = await InternetAddress.lookup(
          _fallbackTestHost,
        ).timeout(_testTimeout);

        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (e) {
        // Both failed
      }
    }
    return false;
  }

  @override
  Future<NetworkConnectionInfo> getConnectionInfo() async {
    final stopwatch = Stopwatch()..start();

    try {
      final hasConnection = await hasInternetAccess();
      final latency = await measureLatency();

      final status = hasConnection
          ? NetworkStatus.connected
          : NetworkStatus.disconnected;

      final quality = _determineQuality(latency, hasConnection);

      return NetworkConnectionInfo(
        status: status,
        quality: quality,
        latency: latency,
        lastChecked: DateTime.now(),
      );
    } catch (e) {
      return NetworkConnectionInfo(
        status: NetworkStatus.unknown,
        quality: NetworkQuality.offline,
        lastChecked: DateTime.now(),
      );
    } finally {
      stopwatch.stop();
    }
  }

  @override
  Future<Duration?> measureLatency() async {
    final stopwatch = Stopwatch()..start();

    try {
      await Socket.connect(
        _primaryTestHost,
        _testPort,
      ).timeout(_latencyTimeout).then((socket) => socket.destroy());

      stopwatch.stop();
      return stopwatch.elapsed;
    } catch (e) {
      // Try fallback
      try {
        stopwatch.reset();
        stopwatch.start();

        await Socket.connect(
          _fallbackTestHost,
          _testPort,
        ).timeout(_latencyTimeout).then((socket) => socket.destroy());

        stopwatch.stop();
        return stopwatch.elapsed;
      } catch (e) {
        return null;
      }
    }
  }

  @override
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _connectivityTimer = Timer.periodic(
      _monitoringInterval,
      (_) => _checkConnectivity(),
    );

    // Initial check
    _checkConnectivity();
  }

  @override
  void stopMonitoring() {
    _connectivityTimer?.cancel();
    _isMonitoring = false;
  }

  /// Checks connectivity and emits changes
  Future<void> _checkConnectivity() async {
    final newInfo = await getConnectionInfo();

    // Only emit if status or quality changed significantly
    if (_shouldEmitUpdate(newInfo)) {
      _lastKnownInfo = newInfo;
      if (!_connectivityController.isClosed) {
        _connectivityController.add(newInfo);
      }
    }
  }

  /// Determines if we should emit an update
  bool _shouldEmitUpdate(NetworkConnectionInfo newInfo) {
    return newInfo.status != _lastKnownInfo.status ||
        newInfo.quality != _lastKnownInfo.quality ||
        (newInfo.latency != null &&
            _lastKnownInfo.latency != null &&
            (newInfo.latency! - _lastKnownInfo.latency!).abs() >
                const Duration(milliseconds: 100));
  }

  /// Determines network quality based on latency and connection status
  NetworkQuality _determineQuality(Duration? latency, bool hasConnection) {
    if (!hasConnection) return NetworkQuality.offline;
    if (latency == null) return NetworkQuality.poor;

    if (latency.inMilliseconds < 100) {
      return NetworkQuality.excellent;
    } else if (latency.inMilliseconds < 300) {
      return NetworkQuality.good;
    } else {
      return NetworkQuality.poor;
    }
  }

  @override
  void dispose() {
    stopMonitoring();
    _connectivityController.close();
  }
}
