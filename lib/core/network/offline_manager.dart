import 'dart:async';
import 'network_info.dart';

/// Manages offline state and provides offline-related functionality
class OfflineManager {
  final NetworkInfo _networkInfo;

  bool _isOffline = false;
  DateTime? _lastOnlineTime;
  DateTime? _offlineSince;

  final StreamController<OfflineState> _offlineStateController =
      StreamController<OfflineState>.broadcast();

  StreamSubscription<NetworkConnectionInfo>? _connectivitySubscription;

  OfflineManager(this._networkInfo) {
    _initialize();
  }

  /// Current offline state
  bool get isOffline => _isOffline;

  /// When the app last went offline
  DateTime? get offlineSince => _offlineSince;

  /// When the app was last online
  DateTime? get lastOnlineTime => _lastOnlineTime;

  /// Stream of offline state changes
  Stream<OfflineState> get onOfflineStateChanged =>
      _offlineStateController.stream;

  /// Initializes the offline manager
  void _initialize() async {
    // Check initial connectivity
    final isConnected = await _networkInfo.isConnected;
    _updateOfflineState(!isConnected);

    // Listen to connectivity changes
    _connectivitySubscription = _networkInfo.onConnectivityChanged.listen(
      (connectionInfo) => _updateOfflineState(!connectionInfo.isConnected),
    );
  }

  /// Updates the offline state
  void _updateOfflineState(bool isOffline) {
    if (_isOffline == isOffline) return;

    final previousState = _isOffline;
    _isOffline = isOffline;

    final now = DateTime.now();

    if (isOffline) {
      _offlineSince = now;
    } else {
      _lastOnlineTime = now;
      _offlineSince = null;
    }

    final state = OfflineState(
      isOffline: isOffline,
      wasOffline: previousState,
      offlineSince: _offlineSince,
      lastOnlineTime: _lastOnlineTime,
      transitionTime: now,
    );

    _offlineStateController.add(state);
  }

  /// Forces a connectivity check
  Future<void> checkConnectivity() async {
    final isConnected = await _networkInfo.isConnected;
    _updateOfflineState(!isConnected);
  }

  /// Gets offline duration if currently offline
  Duration? getOfflineDuration() {
    if (!_isOffline || _offlineSince == null) return null;
    return DateTime.now().difference(_offlineSince!);
  }

  /// Gets time since last online
  Duration? getTimeSinceLastOnline() {
    if (_lastOnlineTime == null) return null;
    return DateTime.now().difference(_lastOnlineTime!);
  }

  /// Checks if we should show offline indicator
  bool shouldShowOfflineIndicator() {
    if (!_isOffline) return false;

    final offlineDuration = getOfflineDuration();
    if (offlineDuration == null) return false;

    // Show indicator after being offline for more than 5 seconds
    return offlineDuration.inSeconds > 5;
  }

  /// Gets offline message based on duration
  String getOfflineMessage() {
    if (!_isOffline) return '';

    final duration = getOfflineDuration();
    if (duration == null) return 'No internet connection';

    if (duration.inMinutes > 60) {
      final hours = duration.inHours;
      return 'Offline for ${hours}h';
    } else if (duration.inMinutes > 1) {
      return 'Offline for ${duration.inMinutes}m';
    } else {
      return 'No internet connection';
    }
  }

  /// Determines if cached data should be used
  bool shouldUseCachedData() {
    return _isOffline;
  }

  /// Determines if operation should be queued for later
  bool shouldQueueOperation() {
    return _isOffline;
  }

  /// Gets retry strategy for offline scenarios
  OfflineRetryStrategy getRetryStrategy() {
    if (!_isOffline) return OfflineRetryStrategy.immediate;

    final duration = getOfflineDuration();
    if (duration == null) return OfflineRetryStrategy.whenOnline;

    if (duration.inMinutes > 30) {
      return OfflineRetryStrategy.manual;
    } else if (duration.inMinutes > 5) {
      return OfflineRetryStrategy.periodic;
    } else {
      return OfflineRetryStrategy.whenOnline;
    }
  }

  /// Disposes resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _offlineStateController.close();
  }
}

/// Represents the offline state at a point in time
class OfflineState {
  final bool isOffline;
  final bool wasOffline;
  final DateTime? offlineSince;
  final DateTime? lastOnlineTime;
  final DateTime transitionTime;

  const OfflineState({
    required this.isOffline,
    required this.wasOffline,
    this.offlineSince,
    this.lastOnlineTime,
    required this.transitionTime,
  });

  /// Whether this represents a transition to offline
  bool get wentOffline => isOffline && !wasOffline;

  /// Whether this represents a transition to online
  bool get wentOnline => !isOffline && wasOffline;

  /// Whether the state changed
  bool get stateChanged => isOffline != wasOffline;

  @override
  String toString() {
    return 'OfflineState(isOffline: $isOffline, wasOffline: $wasOffline, '
        'offlineSince: $offlineSince, lastOnlineTime: $lastOnlineTime)';
  }
}

/// Strategy for retrying operations when offline
enum OfflineRetryStrategy {
  immediate, // Retry immediately when back online
  whenOnline, // Retry when back online with delay
  periodic, // Retry periodically while offline
  manual, // Require manual retry
}
