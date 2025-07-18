import 'dart:async';
import 'dart:math';
import 'failures.dart';
import 'error_handler.dart';

/// Configuration for retry mechanism
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
}

/// Retry mechanism for handling recoverable failures
class RetryMechanism {
  static final Random _random = Random();

  /// Executes a function with retry logic
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    bool Function(Exception)? shouldRetry,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt < config.maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        // Check if we should retry
        if (attempt == config.maxAttempts - 1) {
          // Last attempt, don't retry
          break;
        }

        // Check custom retry condition
        if (shouldRetry != null && !shouldRetry(lastException)) {
          break;
        }

        // Check if error is recoverable
        final failure = ErrorHandler.handleException(lastException);
        if (!ErrorHandler.isRecoverable(failure)) {
          break;
        }

        // Calculate delay for next attempt
        final delay = _calculateDelay(config, attempt);
        await Future.delayed(delay);
      }
    }

    // All attempts failed, throw the last exception
    throw lastException!;
  }

  /// Executes a function with retry logic and returns a Result
  static Future<Result<T, Failure>> executeWithResult<T>(
    Future<T> Function() operation, {
    RetryConfig config = const RetryConfig(),
    bool Function(Exception)? shouldRetry,
  }) async {
    try {
      final result = await execute(
        operation,
        config: config,
        shouldRetry: shouldRetry,
      );
      return Success(result);
    } catch (e) {
      final exception = e is Exception ? e : Exception(e.toString());
      final failure = ErrorHandler.handleException(exception);
      return Error(failure);
    }
  }

  /// Calculates delay for the next retry attempt
  static Duration _calculateDelay(RetryConfig config, int attemptCount) {
    // Calculate exponential backoff
    final exponentialDelay = Duration(
      milliseconds:
          (config.initialDelay.inMilliseconds *
                  pow(config.backoffMultiplier, attemptCount))
              .round(),
    );

    // Apply maximum delay limit
    final clampedDelay = Duration(
      milliseconds: exponentialDelay.inMilliseconds.clamp(
        config.initialDelay.inMilliseconds,
        config.maxDelay.inMilliseconds,
      ),
    );

    // Add jitter if enabled
    if (config.useJitter) {
      final jitterRange = (clampedDelay.inMilliseconds * 0.1).round();
      final jitter = _random.nextInt(jitterRange * 2) - jitterRange;
      return Duration(milliseconds: clampedDelay.inMilliseconds + jitter);
    }

    return clampedDelay;
  }
}

/// Result type for operations that can fail
abstract class Result<T, E> {
  const Result();

  bool get isSuccess => this is Success<T, E>;
  bool get isError => this is Error<T, E>;

  T get value => (this as Success<T, E>).value;
  E get error => (this as Error<T, E>).error;

  /// Transforms the success value
  Result<U, E> map<U>(U Function(T) transform) {
    if (isSuccess) {
      return Success(transform(value));
    } else {
      return Error(error);
    }
  }

  /// Transforms the error value
  Result<T, F> mapError<F>(F Function(E) transform) {
    if (isError) {
      return Error(transform(error));
    } else {
      return Success(value);
    }
  }

  /// Executes a function based on the result
  U fold<U>(U Function(T) onSuccess, U Function(E) onError) {
    if (isSuccess) {
      return onSuccess(value);
    } else {
      return onError(error);
    }
  }
}

/// Success result
class Success<T, E> extends Result<T, E> {
  final T value;

  const Success(this.value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Success<T, E> && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Error result
class Error<T, E> extends Result<T, E> {
  final E error;

  const Error(this.error);

  @override
  String toString() => 'Error($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Error<T, E> && error == other.error;

  @override
  int get hashCode => error.hashCode;
}
