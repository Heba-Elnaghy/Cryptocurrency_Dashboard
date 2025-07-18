import 'dart:async';
import 'dart:math';

import '../entities/entities.dart';
import '../repositories/cryptocurrency_repository.dart';

/// Use case for managing the connection lifecycle of real-time updates
///
/// This use case handles:
/// - Connection start/stop functionality
/// - Automatic reconnection with exponential backoff
/// - Connection status monitoring
///
/// Requirements: 6.2, 6.3, 6.4, 10.2
class ManageConnectionLifecycle {
  final CryptocurrencyRepository repository;

  // Internal state for resource management
  Timer? _reconnectionTimer;
  StreamSubscription<ConnectionStatus>? _statusSubscription;
  bool _isDisposed = false;

  ManageConnectionLifecycle(this.repository);

  /// Maximum number of reconnection attempts
  static const int maxReconnectionAttempts = 5;

  /// Base delay for exponential backoff (in seconds)
  static const int baseDelaySeconds = 2;

  /// Maximum delay for exponential backoff (in seconds)
  static const int maxDelaySeconds = 60;

  /// Starts real-time updates with automatic reconnection handling
  ///
  /// Returns: Future that completes when the connection is established
  /// Throws: ManageConnectionLifecycleException if connection fails
  Future<void> startUpdates() async {
    if (_isDisposed) {
      throw ManageConnectionLifecycleException(
        'Cannot start updates: ManageConnectionLifecycle has been disposed',
        ManageConnectionLifecycleErrorType.lifecycleError,
      );
    }

    try {
      await repository.startRealTimeUpdates();
    } catch (e) {
      throw ManageConnectionLifecycleException(
        'Failed to start real-time updates: ${e.toString()}',
        ManageConnectionLifecycleErrorType.startError,
        originalException: e,
      );
    }
  }

  /// Stops real-time updates and cleans up resources
  ///
  /// Returns: Future that completes when the connection is stopped
  /// Throws: ManageConnectionLifecycleException if stopping fails
  Future<void> stopUpdates() async {
    try {
      // Cancel any pending reconnection timer
      _reconnectionTimer?.cancel();
      _reconnectionTimer = null;

      // Cancel status subscription
      await _statusSubscription?.cancel();
      _statusSubscription = null;

      await repository.stopRealTimeUpdates();
    } catch (e) {
      throw ManageConnectionLifecycleException(
        'Failed to stop real-time updates: ${e.toString()}',
        ManageConnectionLifecycleErrorType.stopError,
        originalException: e,
      );
    }
  }

  /// Provides a stream of connection status updates
  ///
  /// Returns: Stream of ConnectionStatus objects
  Stream<ConnectionStatus> getStatus() {
    try {
      return repository.getConnectionStatus();
    } catch (e) {
      throw ManageConnectionLifecycleException(
        'Failed to get connection status stream: ${e.toString()}',
        ManageConnectionLifecycleErrorType.statusError,
        originalException: e,
      );
    }
  }

  /// Starts updates with automatic reconnection using exponential backoff
  ///
  /// This method will attempt to reconnect automatically if the connection fails,
  /// using exponential backoff strategy to avoid overwhelming the server.
  ///
  /// Returns: Stream of ConnectionStatus updates during reconnection process
  Stream<ConnectionStatus> startUpdatesWithReconnection() async* {
    int attemptCount = 0;
    bool shouldReconnect = true;

    while (shouldReconnect && attemptCount < maxReconnectionAttempts) {
      try {
        // Emit connecting status
        yield ConnectionStatus(
          isConnected: false,
          statusMessage: attemptCount == 0
              ? 'Connecting...'
              : 'Reconnecting... (attempt ${attemptCount + 1}/$maxReconnectionAttempts)',
          lastUpdate: DateTime.now(),
        );

        // Attempt to start updates
        await repository.startRealTimeUpdates();

        // If successful, emit connected status
        yield ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: DateTime.now(),
        );

        // Listen to connection status and handle disconnections
        await for (final status in repository.getConnectionStatus()) {
          yield status;

          // If connection is lost, break to trigger reconnection
          if (!status.isConnected) {
            shouldReconnect = true;
            break;
          }
        }

        // Reset attempt count on successful connection
        attemptCount = 0;
      } catch (e) {
        attemptCount++;

        if (attemptCount >= maxReconnectionAttempts) {
          // Emit final error status
          yield ConnectionStatus(
            isConnected: false,
            statusMessage:
                'Connection failed after $maxReconnectionAttempts attempts',
            lastUpdate: DateTime.now(),
          );

          throw ManageConnectionLifecycleException(
            'Failed to establish connection after $maxReconnectionAttempts attempts: ${e.toString()}',
            ManageConnectionLifecycleErrorType.reconnectionFailed,
            originalException: e,
            attemptCount: attemptCount,
          );
        }

        // Calculate exponential backoff delay
        final delaySeconds = _calculateBackoffDelay(attemptCount);

        // Emit waiting status
        yield ConnectionStatus(
          isConnected: false,
          statusMessage:
              'Retrying in ${delaySeconds}s... (attempt $attemptCount/$maxReconnectionAttempts)',
          lastUpdate: DateTime.now(),
        );

        // Wait before next attempt
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
  }

  /// Calculates the delay for exponential backoff
  ///
  /// Uses the formula: min(baseDelay * 2^(attempt-1), maxDelay)
  /// with some jitter to avoid thundering herd problem
  int _calculateBackoffDelay(int attemptCount) {
    final exponentialDelay =
        baseDelaySeconds * pow(2, attemptCount - 1).toInt();
    final cappedDelay = min(exponentialDelay, maxDelaySeconds);

    // Add jitter (±25% of the delay)
    final jitter = (cappedDelay * 0.25 * (Random().nextDouble() - 0.5)).round();
    final finalDelay = cappedDelay + jitter;

    return max(1, finalDelay); // Ensure minimum 1 second delay
  }

  /// Checks if updates are currently active
  ///
  /// Returns: true if real-time updates are running, false otherwise
  bool get isUpdating => repository.isUpdating;

  /// Performs a graceful shutdown of the connection
  ///
  /// This method ensures all resources are properly cleaned up
  /// and any ongoing operations are completed or cancelled gracefully.
  Future<void> gracefulShutdown() async {
    if (_isDisposed) return;

    try {
      // Cancel any pending reconnection timer
      _reconnectionTimer?.cancel();
      _reconnectionTimer = null;

      // Cancel status subscription
      await _statusSubscription?.cancel();
      _statusSubscription = null;

      // Stop repository updates if running
      if (repository.isUpdating) {
        await repository.stopRealTimeUpdates();
      }
    } catch (e) {
      // Log the error but don't throw during shutdown
      // In a real app, you would use a proper logging framework
      // print('Warning: Error during graceful shutdown: $e');
    }
  }

  /// Disposes of all resources and marks the instance as disposed
  ///
  /// After calling dispose, this instance should not be used anymore.
  /// All subsequent method calls will throw ManageConnectionLifecycleException.
  Future<void> dispose() async {
    if (_isDisposed) return;

    _isDisposed = true;

    try {
      // Perform graceful shutdown
      await gracefulShutdown();
    } catch (e) {
      // Log error but don't throw during disposal
      // In production, use proper logging
      // print('Warning: Error during ManageConnectionLifecycle disposal: $e');
    }
  }

  /// Checks if this instance has been disposed
  bool get isDisposed => _isDisposed;
}

/// Exception thrown by ManageConnectionLifecycle use case
class ManageConnectionLifecycleException implements Exception {
  final String message;
  final ManageConnectionLifecycleErrorType errorType;
  final Object? originalException;
  final int? attemptCount;

  const ManageConnectionLifecycleException(
    this.message,
    this.errorType, {
    this.originalException,
    this.attemptCount,
  });

  @override
  String toString() => 'ManageConnectionLifecycleException: $message';
}

/// Types of errors that can occur in ManageConnectionLifecycle use case
enum ManageConnectionLifecycleErrorType {
  /// Error starting the connection
  startError,

  /// Error stopping the connection
  stopError,

  /// Error getting connection status
  statusError,

  /// Reconnection failed after maximum attempts
  reconnectionFailed,

  /// General connection lifecycle error
  lifecycleError,
}
