import 'dart:async';
import 'dart:math';
import 'failures.dart';
import 'error_handler.dart';
import 'exceptions.dart';

/// Configuration for retry mechanisms
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool useJitter;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
  });

  /// Default configuration for API calls
  static const api = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 30),
    backoffMultiplier: 2.0,
  );

  /// Configuration for network operations
  static const network = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 60),
    backoffMultiplier: 1.5,
  );

  /// Configuration for critical operations
  static const critical = RetryConfig(
    maxAttempts: 10,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(minutes: 2),
    backoffMultiplier: 1.8,
  );
}

/// Result of a recovery attempt
class RecoveryResult<T> {
  final T? data;
  final Failure? failure;
  final bool isSuccess;
  final int attemptCount;

  const RecoveryResult._({
    this.data,
    this.failure,
    required this.isSuccess,
    required this.attemptCount,
  });

  factory RecoveryResult.success(T data, int attemptCount) {
    return RecoveryResult._(
      data: data,
      isSuccess: true,
      attemptCount: attemptCount,
    );
  }

  factory RecoveryResult.failure(Failure failure, int attemptCount) {
    return RecoveryResult._(
      failure: failure,
      isSuccess: false,
      attemptCount: attemptCount,
    );
  }
}

/// Handles error recovery and retry mechanisms
class ErrorRecovery {
  static final Random _random = Random();

  /// Executes an operation with retry logic
  static Future<RecoveryResult<T>> withRetry<T>(
    Future<T> Function() operation, {
    RetryConfig config = RetryConfig.api,
    bool Function(Failure)? shouldRetry,
  }) async {
    int attemptCount = 0;
    Failure? lastFailure;

    while (attemptCount < config.maxAttempts) {
      attemptCount++;

      try {
        final result = await operation();
        return RecoveryResult.success(result, attemptCount);
      } catch (exception) {
        final failure = ErrorHandler.handleException(exception as Exception);
        lastFailure = failure;

        // Check if we should retry
        final canRetry =
            shouldRetry?.call(failure) ?? ErrorHandler.isRecoverable(failure);

        if (!canRetry || attemptCount >= config.maxAttempts) {
          break;
        }

        // Calculate delay for next attempt
        final delay = _calculateDelay(config, attemptCount);
        await Future.delayed(delay);
      }
    }

    return RecoveryResult.failure(
      lastFailure ?? const UnknownFailure(message: 'Unknown error'),
      attemptCount,
    );
  }

  /// Executes an operation with circuit breaker pattern
  static Future<RecoveryResult<T>> withCircuitBreaker<T>(
    Future<T> Function() operation,
    CircuitBreakerConfig config,
  ) async {
    final circuitBreaker = CircuitBreaker(config);

    try {
      final result = await circuitBreaker.execute(operation);
      return RecoveryResult.success(result, 1);
    } catch (exception) {
      final failure = ErrorHandler.handleException(exception as Exception);
      return RecoveryResult.failure(failure, 1);
    }
  }

  /// Calculates delay with exponential backoff and optional jitter
  static Duration _calculateDelay(RetryConfig config, int attemptCount) {
    final baseDelay = config.initialDelay.inMilliseconds;
    final exponentialDelay =
        (baseDelay * pow(config.backoffMultiplier, attemptCount - 1)).round();

    final clampedDelay = exponentialDelay.clamp(
      config.initialDelay.inMilliseconds,
      config.maxDelay.inMilliseconds,
    );

    if (config.useJitter) {
      // Add jitter to prevent thundering herd
      final jitter = (_random.nextDouble() * 0.1 * clampedDelay).round();
      return Duration(milliseconds: clampedDelay + jitter);
    }

    return Duration(milliseconds: clampedDelay);
  }

  /// Creates a retry function for specific failure types
  static bool Function(Failure) retryOn(List<Type> failureTypes) {
    return (failure) => failureTypes.contains(failure.runtimeType);
  }

  /// Creates a retry function that excludes specific failure types
  static bool Function(Failure) retryExcept(List<Type> failureTypes) {
    return (failure) => !failureTypes.contains(failure.runtimeType);
  }
}

/// Configuration for circuit breaker pattern
class CircuitBreakerConfig {
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;

  const CircuitBreakerConfig({
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 30),
    this.resetTimeout = const Duration(minutes: 1),
  });
}

/// Circuit breaker states
enum CircuitBreakerState { closed, open, halfOpen }

/// Circuit breaker implementation
class CircuitBreaker {
  final CircuitBreakerConfig config;
  CircuitBreakerState _state = CircuitBreakerState.closed;
  int _failureCount = 0;
  DateTime? _lastFailureTime;

  CircuitBreaker(this.config);

  /// Executes an operation through the circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
      } else {
        throw const NetworkException(
          message: 'Circuit breaker is open',
          details: 'Service is temporarily unavailable',
        );
      }
    }

    try {
      final result = await operation().timeout(config.timeout);
      _onSuccess();
      return result;
    } catch (exception) {
      _onFailure();
      rethrow;
    }
  }

  /// Checks if circuit breaker should attempt reset
  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;

    return DateTime.now().difference(_lastFailureTime!) > config.resetTimeout;
  }

  /// Handles successful operation
  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
  }

  /// Handles failed operation
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= config.failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }

  /// Gets current circuit breaker state
  CircuitBreakerState get state => _state;

  /// Gets current failure count
  int get failureCount => _failureCount;
}
