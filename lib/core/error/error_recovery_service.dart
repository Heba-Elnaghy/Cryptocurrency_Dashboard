import 'dart:async';
import 'package:flutter/foundation.dart';
import 'failures.dart';
import 'error_handler.dart';
import 'error_recovery.dart';
import '../network/network_info.dart';

/// Service that provides comprehensive error recovery mechanisms
class ErrorRecoveryService {
  final NetworkInfo _networkInfo;
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  final StreamController<RecoveryEvent> _recoveryEventController =
      StreamController<RecoveryEvent>.broadcast();

  ErrorRecoveryService(this._networkInfo);

  /// Stream of recovery events for monitoring
  Stream<RecoveryEvent> get recoveryEvents => _recoveryEventController.stream;

  /// Executes an operation with comprehensive error recovery
  Future<T> executeWithRecovery<T>(
    String operationId,
    Future<T> Function() operation, {
    RetryConfig? retryConfig,
    CircuitBreakerConfig? circuitBreakerConfig,
    bool requiresNetwork = true,
    bool Function(Failure)? shouldRetry,
  }) async {
    // Check network connectivity if required
    if (requiresNetwork && !await _networkInfo.isConnected) {
      final failure = const NetworkFailure(
        message: 'No internet connection',
        details: 'Please check your network connection and try again',
      );
      _emitRecoveryEvent(RecoveryEvent.failed(operationId, failure));
      throw failure;
    }

    try {
      // Use circuit breaker if configured
      if (circuitBreakerConfig != null) {
        return await _executeWithCircuitBreaker(
          operationId,
          operation,
          circuitBreakerConfig,
        );
      }

      // Use retry mechanism
      final config = retryConfig ?? RetryConfig.api;
      final result = await ErrorRecovery.withRetry(
        operation,
        config: config,
        shouldRetry: shouldRetry ?? _defaultShouldRetry,
      );

      if (result.isSuccess) {
        _emitRecoveryEvent(
          RecoveryEvent.succeeded(operationId, result.attemptCount),
        );
        return result.data!;
      } else {
        _emitRecoveryEvent(RecoveryEvent.failed(operationId, result.failure!));
        throw result.failure!;
      }
    } catch (error) {
      final failure = error is Failure
          ? error
          : ErrorHandler.handleException(error as Exception);
      _emitRecoveryEvent(RecoveryEvent.failed(operationId, failure));
      rethrow;
    }
  }

  /// Executes operation with circuit breaker
  Future<T> _executeWithCircuitBreaker<T>(
    String operationId,
    Future<T> Function() operation,
    CircuitBreakerConfig config,
  ) async {
    final circuitBreaker = _getOrCreateCircuitBreaker(operationId, config);

    try {
      final result = await circuitBreaker.execute(operation);
      _emitRecoveryEvent(RecoveryEvent.succeeded(operationId, 1));
      return result;
    } catch (error) {
      final failure = error is Failure
          ? error
          : ErrorHandler.handleException(error as Exception);

      _emitRecoveryEvent(
        RecoveryEvent.circuitBreakerTripped(
          operationId,
          circuitBreaker.state,
          circuitBreaker.failureCount,
        ),
      );

      throw failure;
    }
  }

  /// Gets or creates a circuit breaker for an operation
  CircuitBreaker _getOrCreateCircuitBreaker(
    String operationId,
    CircuitBreakerConfig config,
  ) {
    return _circuitBreakers.putIfAbsent(
      operationId,
      () => CircuitBreaker(config),
    );
  }

  /// Default retry logic
  bool _defaultShouldRetry(Failure failure) {
    // Don't retry on client errors (4xx) except rate limiting
    if (failure is ApiFailure) {
      final statusCode = failure.errorCode;
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        return statusCode == 429; // Only retry on rate limiting
      }
    }

    // Retry on network, timeout, and server errors
    return failure is NetworkFailure ||
        failure is TimeoutFailure ||
        failure is ConnectionFailure ||
        (failure is ApiFailure && (failure.errorCode ?? 0) >= 500);
  }

  /// Emits a recovery event
  void _emitRecoveryEvent(RecoveryEvent event) {
    if (!_recoveryEventController.isClosed) {
      _recoveryEventController.add(event);
    }

    // Log in debug mode
    if (kDebugMode) {
      debugPrint('Recovery Event: ${event.toString()}');
    }
  }

  /// Gets the current state of a circuit breaker
  CircuitBreakerState? getCircuitBreakerState(String operationId) {
    return _circuitBreakers[operationId]?.state;
  }

  /// Resets a circuit breaker
  void resetCircuitBreaker(String operationId) {
    _circuitBreakers.remove(operationId);
  }

  /// Disposes the service
  void dispose() {
    _recoveryEventController.close();
    _circuitBreakers.clear();
  }
}

/// Events emitted during error recovery
abstract class RecoveryEvent {
  final String operationId;
  final DateTime timestamp;

  RecoveryEvent(this.operationId) : timestamp = DateTime.now();

  factory RecoveryEvent.succeeded(String operationId, int attemptCount) =>
      RecoverySucceeded(operationId, attemptCount);

  factory RecoveryEvent.failed(String operationId, Failure failure) =>
      RecoveryFailed(operationId, failure);

  factory RecoveryEvent.retrying(
    String operationId,
    int attemptCount,
    Duration delay,
  ) => RecoveryRetrying(operationId, attemptCount, delay);

  factory RecoveryEvent.circuitBreakerTripped(
    String operationId,
    CircuitBreakerState state,
    int failureCount,
  ) => CircuitBreakerTripped(operationId, state, failureCount);

  @override
  String toString() => 'RecoveryEvent($operationId at $timestamp)';
}

/// Recovery succeeded event
class RecoverySucceeded extends RecoveryEvent {
  final int attemptCount;

  RecoverySucceeded(super.operationId, this.attemptCount);

  @override
  String toString() =>
      'RecoverySucceeded($operationId, attempts: $attemptCount)';
}

/// Recovery failed event
class RecoveryFailed extends RecoveryEvent {
  final Failure failure;

  RecoveryFailed(super.operationId, this.failure);

  @override
  String toString() => 'RecoveryFailed($operationId, ${failure.message})';
}

/// Recovery retrying event
class RecoveryRetrying extends RecoveryEvent {
  final int attemptCount;
  final Duration delay;

  RecoveryRetrying(super.operationId, this.attemptCount, this.delay);

  @override
  String toString() =>
      'RecoveryRetrying($operationId, attempt: $attemptCount, delay: ${delay.inMilliseconds}ms)';
}

/// Circuit breaker tripped event
class CircuitBreakerTripped extends RecoveryEvent {
  final CircuitBreakerState state;
  final int failureCount;

  CircuitBreakerTripped(super.operationId, this.state, this.failureCount);

  @override
  String toString() =>
      'CircuitBreakerTripped($operationId, state: $state, failures: $failureCount)';
}
