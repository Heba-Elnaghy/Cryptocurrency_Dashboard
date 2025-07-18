import 'dart:async';
import 'dart:io';

/// Detects offline state and manages offline transitions
class OfflineDetector {

  Timer? _detectionTimer;
  bool _isMonitoring = false;

  // Detection configuration
  static const Duration _detectionInterval = Duration(seconds: 2);
  static const Duration _offlineThreshold = Duration(seconds: 5);
  static const int _consecutiveFailures = 3;

  int _failureCount = 0;
  DateTime? _lastSuccessfulCheck;

  final StreamController<OfflineDetectionEvent> _eventController =
      StreamController<OfflineDetectionEvent>.broadcast();

  OfflineDetector();

  /// Stream of offline detection events
  Stream<OfflineDetectionEvent> get events => _eventController.stream;

  /// Current failure count
  int get failureCount => _failureCount;

  /// Last successful connectivity check
  DateTime? get lastSuccessfulCheck => _lastSuccessfulCheck;

  /// Whether offline detection is active
  bool get isMonitoring => _isMonitoring;

  /// Starts offline detection monitoring
  void startDetection() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _failureCount = 0;
    _lastSuccessfulCheck = DateTime.now();

    _detectionTimer = Timer.periodic(
      _detectionInterval,
      (_) => _performCheck(),
    );

    // Perform initial check
    _performCheck();

    _emitEvent(OfflineDetectionEvent.started());
  }

  /// Stops offline detection monitoring
  void stopDetection() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    _detectionTimer?.cancel();
    _detectionTimer = null;

    _emitEvent(OfflineDetectionEvent.stopped());
  }

  /// Performs a connectivity check
  Future<void> _performCheck() async {
    if (!_isMonitoring) return;

    try {
      final isConnected = await _checkConnectivity();

      if (isConnected) {
        _handleSuccessfulCheck();
      } else {
        _handleFailedCheck();
      }
    } catch (e) {
      _handleFailedCheck();
    }
  }

  /// Checks connectivity using multiple methods
  Future<bool> _checkConnectivity() async {
    try {
      // Primary check: DNS lookup
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (e) {
      // Fallback check: Socket connection
      try {
        final socket = await Socket.connect(
          '8.8.8.8',
          53,
        ).timeout(const Duration(seconds: 2));
        socket.destroy();
        return true;
      } catch (e) {
        // Both checks failed
      }
    }

    return false;
  }

  /// Handles successful connectivity check
  void _handleSuccessfulCheck() {
    final wasOffline = _failureCount >= _consecutiveFailures;

    _failureCount = 0;
    _lastSuccessfulCheck = DateTime.now();

    if (wasOffline) {
      _emitEvent(OfflineDetectionEvent.backOnline());
    }

    _emitEvent(OfflineDetectionEvent.checkSucceeded());
  }

  /// Handles failed connectivity check
  void _handleFailedCheck() {
    _failureCount++;

    final wasOnline = _failureCount == _consecutiveFailures;

    if (wasOnline) {
      _emitEvent(OfflineDetectionEvent.wentOffline());
    }

    _emitEvent(OfflineDetectionEvent.checkFailed(_failureCount));
  }

  /// Forces an immediate connectivity check
  Future<bool> forceCheck() async {
    final isConnected = await _checkConnectivity();

    if (isConnected) {
      _handleSuccessfulCheck();
    } else {
      _handleFailedCheck();
    }

    return isConnected;
  }

  /// Gets the current offline status
  bool get isOffline => _failureCount >= _consecutiveFailures;

  /// Gets time since last successful check
  Duration? getTimeSinceLastSuccess() {
    if (_lastSuccessfulCheck == null) return null;
    return DateTime.now().difference(_lastSuccessfulCheck!);
  }

  /// Determines if we should show offline warning
  bool shouldShowOfflineWarning() {
    if (!isOffline) return false;

    final timeSinceSuccess = getTimeSinceLastSuccess();
    return timeSinceSuccess != null && timeSinceSuccess > _offlineThreshold;
  }

  /// Gets appropriate offline message
  String getOfflineMessage() {
    if (!isOffline) return '';

    final timeSinceSuccess = getTimeSinceLastSuccess();
    if (timeSinceSuccess == null) return 'Connection lost';

    if (timeSinceSuccess.inMinutes > 60) {
      return 'Offline for ${timeSinceSuccess.inHours}h';
    } else if (timeSinceSuccess.inMinutes > 1) {
      return 'Offline for ${timeSinceSuccess.inMinutes}m';
    } else {
      return 'Connection lost';
    }
  }

  /// Emits an offline detection event
  void _emitEvent(OfflineDetectionEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Disposes resources
  void dispose() {
    stopDetection();
    _eventController.close();
  }
}

/// Events emitted by the offline detector
abstract class OfflineDetectionEvent {
  final DateTime timestamp;

  OfflineDetectionEvent() : timestamp = DateTime.now();

  factory OfflineDetectionEvent.started() => OfflineDetectionStarted();
  factory OfflineDetectionEvent.stopped() => OfflineDetectionStopped();
  factory OfflineDetectionEvent.checkSucceeded() =>
      OfflineDetectionCheckSucceeded();
  factory OfflineDetectionEvent.checkFailed(int failureCount) =>
      OfflineDetectionCheckFailed(failureCount);
  factory OfflineDetectionEvent.wentOffline() => OfflineDetectionWentOffline();
  factory OfflineDetectionEvent.backOnline() => OfflineDetectionBackOnline();
}

class OfflineDetectionStarted extends OfflineDetectionEvent {
  @override
  String toString() => 'Offline detection started';
}

class OfflineDetectionStopped extends OfflineDetectionEvent {
  @override
  String toString() => 'Offline detection stopped';
}

class OfflineDetectionCheckSucceeded extends OfflineDetectionEvent {
  @override
  String toString() => 'Connectivity check succeeded';
}

class OfflineDetectionCheckFailed extends OfflineDetectionEvent {
  final int failureCount;

  OfflineDetectionCheckFailed(this.failureCount);

  @override
  String toString() => 'Connectivity check failed (failures: $failureCount)';
}

class OfflineDetectionWentOffline extends OfflineDetectionEvent {
  @override
  String toString() => 'Device went offline';
}

class OfflineDetectionBackOnline extends OfflineDetectionEvent {
  @override
  String toString() => 'Device back online';
}
