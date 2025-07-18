import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:dio/dio.dart';
import '../error/error_handling.dart';
import 'network_info.dart';
import 'offline_manager.dart';
import 'offline_detector.dart';

/// Specialized error handler for network-related operations with enhanced retry logic
class NetworkErrorHandler {
  final NetworkInfo _networkInfo;
  final OfflineManager? _offlineManager;
  final OfflineDetector? _offlineDetector;

  NetworkErrorHandler(
    this._networkInfo, {
    OfflineManager? offlineManager,
    OfflineDetector? offlineDetector,
  }) : _offlineManager = offlineManager,
       _offlineDetector = offlineDetector;

  /// Handles network-specific exceptions with context
  Future<Failure> handleNetworkException(Exception exception) async {
    final isConnected = await _networkInfo.isConnected;

    if (!isConnected) {
      return const NetworkFailure(
        message: 'No internet connection',
        details: 'Please check your network connection and try again',
      );
    }

    if (exception is DioException) {
      return _handleDioNetworkException(exception);
    } else if (exception is SocketException) {
      return _handleSocketException(exception);
    } else if (exception is TimeoutException) {
      return TimeoutFailure(
        message: 'Operation timed out',
        details: exception.message,
      );
    } else {
      return NetworkFailure(
        message: 'Network error occurred',
        details: exception.toString(),
      );
    }
  }

  /// Handles Dio network exceptions with enhanced context
  Failure _handleDioNetworkException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
        return const TimeoutFailure(
          message: 'Connection timeout',
          details:
              'Unable to establish connection within the timeout period. This might be due to slow network or server issues.',
        );

      case DioExceptionType.sendTimeout:
        return const TimeoutFailure(
          message: 'Send timeout',
          details:
              'Failed to send data within the timeout period. Your connection might be slow.',
        );

      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure(
          message: 'Receive timeout',
          details:
              'Server took too long to respond. This might be due to server overload or network issues.',
        );

      case DioExceptionType.connectionError:
        return const ConnectionFailure(
          message: 'Connection failed',
          details:
              'Unable to connect to the server. Please check your internet connection or try again later.',
        );

      case DioExceptionType.badResponse:
        return _handleBadNetworkResponse(exception);

      case DioExceptionType.cancel:
        return const NetworkFailure(
          message: 'Request cancelled',
          details: 'The network request was cancelled',
        );

      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          message: 'SSL certificate error',
          details:
              'SSL certificate verification failed. This might be a security issue.',
        );

      case DioExceptionType.unknown:
      return NetworkFailure(
          message: 'Unknown network error',
          details: exception.message ?? 'An unexpected network error occurred',
        );
    }
  }

  /// Handles bad HTTP responses with network context
  Failure _handleBadNetworkResponse(DioException exception) {
    final statusCode = exception.response?.statusCode;

    switch (statusCode) {
      case 408: // Request Timeout
        return const TimeoutFailure(
          message: 'Request timeout',
          details:
              'The server did not receive the request within the timeout period',
          errorCode: 408,
        );

      case 429: // Too Many Requests
        return const ApiFailure(
          message: 'Rate limit exceeded',
          details: 'Too many requests sent. Please wait before trying again.',
          errorCode: 429,
        );

      case 500: // Internal Server Error
        return const ApiFailure(
          message: 'Server error',
          details:
              'The server encountered an internal error. Please try again later.',
          errorCode: 500,
        );

      case 502: // Bad Gateway
        return const ApiFailure(
          message: 'Bad gateway',
          details:
              'The server received an invalid response from upstream server.',
          errorCode: 502,
        );

      case 503: // Service Unavailable
        return const ApiFailure(
          message: 'Service unavailable',
          details:
              'The server is temporarily unavailable due to maintenance or overload.',
          errorCode: 503,
        );

      case 504: // Gateway Timeout
        return const TimeoutFailure(
          message: 'Gateway timeout',
          details:
              'The server did not receive a timely response from upstream server.',
          errorCode: 504,
        );

      default:
        return ApiFailure(
          message: 'HTTP error',
          details: 'Server returned status code: $statusCode',
          errorCode: statusCode,
        );
    }
  }

  /// Handles socket exceptions
  Failure _handleSocketException(SocketException exception) {
    switch (exception.osError?.errorCode) {
      case 7: // No address associated with hostname
        return const NetworkFailure(
          message: 'DNS resolution failed',
          details: 'Unable to resolve server address. Check your DNS settings.',
        );

      case 61: // Connection refused
        return const ConnectionFailure(
          message: 'Connection refused',
          details:
              'The server refused the connection. The service might be down.',
        );

      case 64: // Host is down
        return const ConnectionFailure(
          message: 'Host unreachable',
          details: 'The server is unreachable. It might be down or blocked.',
        );

      case 65: // No route to host
        return const NetworkFailure(
          message: 'No route to host',
          details:
              'Unable to reach the server. Check your network configuration.',
        );

      default:
        return NetworkFailure(
          message: 'Socket error',
          details: exception.message,
        );
    }
  }

  /// Determines if a failure should trigger offline mode
  bool shouldGoOffline(Failure failure) {
    return failure is NetworkFailure &&
        (failure.message.contains('No internet connection') ||
            failure.message.contains('DNS resolution failed'));
  }

  /// Gets appropriate retry delay based on network failure type
  Duration getNetworkRetryDelay(Failure failure, int attemptCount) {
    Duration baseDelay;

    if (failure is TimeoutFailure) {
      baseDelay = const Duration(seconds: 5); // Longer delay for timeouts
    } else if (failure is ApiFailure && failure.errorCode == 429) {
      baseDelay = const Duration(seconds: 10); // Longer delay for rate limits
    } else {
      baseDelay = const Duration(seconds: 2); // Standard delay
    }

    // Exponential backoff with jitter
    final exponentialDelay = Duration(
      milliseconds: (baseDelay.inMilliseconds * (1 << attemptCount)).clamp(
        baseDelay.inMilliseconds,
        60000, // Max 1 minute for network errors
      ),
    );

    return exponentialDelay;
  }

  /// Creates a network-aware retry configuration
  RetryConfig createNetworkRetryConfig({
    int maxAttempts = 3,
    Duration? initialDelay,
  }) {
    return RetryConfig(
      maxAttempts: maxAttempts,
      initialDelay: initialDelay ?? const Duration(seconds: 2),
      maxDelay: const Duration(minutes: 1),
      backoffMultiplier: 2.0,
      useJitter: true,
    );
  }

  /// Executes operation with network-aware error handling
  Future<T> executeWithNetworkHandling<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    bool Function(Failure)? shouldRetry,
  }) async {
    int attemptCount = 0;
    Exception? lastException;

    while (attemptCount < maxAttempts) {
      attemptCount++;

      try {
        return await operation();
      } catch (exception) {
        lastException = exception as Exception;
        final failure = await handleNetworkException(exception);

        // Custom retry condition
        if (shouldRetry != null && !shouldRetry(failure)) {
          break;
        }

        // Don't retry if offline
        if (shouldGoOffline(failure)) {
          break;
        }

        // Check if error is recoverable
        if (!ErrorHandler.isRecoverable(failure)) {
          break;
        }

        // Don't retry on last attempt
        if (attemptCount >= maxAttempts) {
          break;
        }

        // Calculate delay for next attempt
        final delay = getNetworkRetryDelay(failure, attemptCount);
        await Future.delayed(delay);
      }
    }

    // All attempts failed, throw the last exception
    throw lastException!;
  }

  /// Executes operation with enhanced network error handling and offline detection
  Future<NetworkOperationResult<T>> executeWithEnhancedHandling<T>(
    Future<T> Function() operation, {
    NetworkRetryConfig? config,
    bool Function(Failure)? shouldRetry,
    void Function(NetworkOperationEvent)? onEvent,
  }) async {
    final effectiveConfig = config ?? NetworkRetryConfig.standard();
    int attemptCount = 0;
    Failure? lastFailure;
    final events = <NetworkOperationEvent>[];

    while (attemptCount < effectiveConfig.maxAttempts) {
      attemptCount++;

      // Check offline status before attempting
      if (_offlineManager?.isOffline == true &&
          effectiveConfig.skipWhenOffline) {
        final failure = const NetworkFailure(
          message: 'Device is offline',
          details: 'Operation skipped due to offline status',
        );
        final event = NetworkOperationEvent.skippedOffline(attemptCount);
        events.add(event);
        onEvent?.call(event);

        return NetworkOperationResult.failure(failure, attemptCount, events);
      }

      try {
        final event = NetworkOperationEvent.attempting(attemptCount);
        events.add(event);
        onEvent?.call(event);

        final result = await operation();

        final successEvent = NetworkOperationEvent.succeeded(attemptCount);
        events.add(successEvent);
        onEvent?.call(successEvent);

        return NetworkOperationResult.success(result, attemptCount, events);
      } catch (exception) {
        final failure = await handleNetworkException(exception as Exception);
        lastFailure = failure;

        final failedEvent = NetworkOperationEvent.failed(attemptCount, failure);
        events.add(failedEvent);
        onEvent?.call(failedEvent);

        // Check if we should retry
        if (!_shouldRetryWithConfig(
          failure,
          attemptCount,
          effectiveConfig,
          shouldRetry,
        )) {
          break;
        }

        // Calculate delay for next attempt
        final delay = _calculateEnhancedRetryDelay(
          failure,
          attemptCount,
          effectiveConfig,
        );

        final retryEvent = NetworkOperationEvent.retrying(attemptCount, delay);
        events.add(retryEvent);
        onEvent?.call(retryEvent);

        await Future.delayed(delay);
      }
    }

    return NetworkOperationResult.failure(
      lastFailure ?? const UnknownFailure(message: 'Operation failed'),
      attemptCount,
      events,
    );
  }

  /// Determines if operation should be retried with enhanced config
  bool _shouldRetryWithConfig(
    Failure failure,
    int attemptCount,
    NetworkRetryConfig config,
    bool Function(Failure)? customShouldRetry,
  ) {
    // Don't retry if we've reached max attempts
    if (attemptCount >= config.maxAttempts) return false;

    // Check custom retry condition first
    if (customShouldRetry != null && !customShouldRetry(failure)) {
      return false;
    }

    // Don't retry if offline and configured to skip
    if (_offlineManager?.isOffline == true && config.skipWhenOffline) {
      return false;
    }

    // Check failure-specific retry conditions
    if (failure is TimeoutFailure) {
      return config.retryOnTimeout;
    }

    if (failure is ConnectionFailure) {
      return config.retryOnConnectionError;
    }

    if (failure is ApiFailure) {
      if (failure.errorCode == 429) {
        return config.retryOnRateLimit;
      }
      if (failure.errorCode != null && failure.errorCode! >= 500) {
        return config.retryOnServerError;
      }
    }

    if (failure is NetworkFailure) {
      return config.retryOnNetworkError;
    }

    return false;
  }

  /// Calculates enhanced retry delay with multiple strategies
  Duration _calculateEnhancedRetryDelay(
    Failure failure,
    int attemptCount,
    NetworkRetryConfig config,
  ) {
    Duration baseDelay;

    // Determine base delay based on failure type
    if (failure is TimeoutFailure) {
      baseDelay = config.timeoutRetryDelay;
    } else if (failure is ApiFailure && failure.errorCode == 429) {
      baseDelay = config.rateLimitRetryDelay;
    } else if (failure is ConnectionFailure) {
      baseDelay = config.connectionRetryDelay;
    } else {
      baseDelay = config.baseRetryDelay;
    }

    // Apply backoff strategy
    Duration calculatedDelay;
    switch (config.backoffStrategy) {
      case BackoffStrategy.exponential:
        calculatedDelay = Duration(
          milliseconds:
              (baseDelay.inMilliseconds *
                      pow(config.backoffMultiplier, attemptCount - 1))
                  .round(),
        );
        break;
      case BackoffStrategy.linear:
        calculatedDelay = Duration(
          milliseconds: baseDelay.inMilliseconds * attemptCount,
        );
        break;
      case BackoffStrategy.fixed:
        calculatedDelay = baseDelay;
        break;
    }

    // Apply maximum delay limit
    calculatedDelay = Duration(
      milliseconds: calculatedDelay.inMilliseconds.clamp(
        baseDelay.inMilliseconds,
        config.maxRetryDelay.inMilliseconds,
      ),
    );

    // Add jitter if enabled
    if (config.useJitter) {
      final jitterRange = (calculatedDelay.inMilliseconds * config.jitterFactor)
          .round();
      final random = Random();
      final jitter = random.nextInt(jitterRange * 2) - jitterRange;
      calculatedDelay = Duration(
        milliseconds: (calculatedDelay.inMilliseconds + jitter).clamp(
          baseDelay.inMilliseconds ~/ 2,
          config.maxRetryDelay.inMilliseconds,
        ),
      );
    }

    return calculatedDelay;
  }

  /// Handles timeout-specific errors with enhanced context
  Future<Failure> handleTimeoutError(
    TimeoutException exception,
    Duration timeoutDuration,
  ) async {
    final connectionInfo = await _networkInfo.getConnectionInfo();

    String details =
        'Operation timed out after ${timeoutDuration.inSeconds} seconds.';

    if (connectionInfo.quality == NetworkQuality.poor) {
      details += ' Your connection appears to be slow.';
    } else if (connectionInfo.latency != null &&
        connectionInfo.latency!.inMilliseconds > 1000) {
      details +=
          ' High network latency detected (${connectionInfo.latency!.inMilliseconds}ms).';
    }

    return TimeoutFailure(message: 'Request timeout', details: details);
  }

  /// Handles connection-specific errors with enhanced context
  Future<Failure> handleConnectionError(Exception exception) async {
    final isConnected = await _networkInfo.isConnected;

    if (!isConnected) {
      // Trigger offline detection if available
      _offlineDetector?.forceCheck();

      return const ConnectionFailure(
        message: 'No internet connection',
        details: 'Please check your network connection and try again.',
      );
    }

    if (exception is SocketException) {
      return _handleSocketException(exception);
    }

    return ConnectionFailure(
      message: 'Connection failed',
      details: 'Unable to establish connection: ${exception.toString()}',
    );
  }

  /// Gets network quality-aware retry configuration
  Future<NetworkRetryConfig> getAdaptiveRetryConfig() async {
    final connectionInfo = await _networkInfo.getConnectionInfo();

    switch (connectionInfo.quality) {
      case NetworkQuality.excellent:
        return NetworkRetryConfig.fast();
      case NetworkQuality.good:
        return NetworkRetryConfig.standard();
      case NetworkQuality.poor:
        return NetworkRetryConfig.slow();
      case NetworkQuality.offline:
        return NetworkRetryConfig.offline();
    }
  }
}

/// Enhanced configuration for network retry operations
class NetworkRetryConfig {
  final int maxAttempts;
  final Duration baseRetryDelay;
  final Duration maxRetryDelay;
  final Duration timeoutRetryDelay;
  final Duration rateLimitRetryDelay;
  final Duration connectionRetryDelay;
  final double backoffMultiplier;
  final BackoffStrategy backoffStrategy;
  final bool useJitter;
  final double jitterFactor;
  final bool retryOnTimeout;
  final bool retryOnConnectionError;
  final bool retryOnNetworkError;
  final bool retryOnServerError;
  final bool retryOnRateLimit;
  final bool skipWhenOffline;

  const NetworkRetryConfig({
    this.maxAttempts = 3,
    this.baseRetryDelay = const Duration(seconds: 2),
    this.maxRetryDelay = const Duration(minutes: 1),
    this.timeoutRetryDelay = const Duration(seconds: 5),
    this.rateLimitRetryDelay = const Duration(seconds: 10),
    this.connectionRetryDelay = const Duration(seconds: 3),
    this.backoffMultiplier = 2.0,
    this.backoffStrategy = BackoffStrategy.exponential,
    this.useJitter = true,
    this.jitterFactor = 0.1,
    this.retryOnTimeout = true,
    this.retryOnConnectionError = true,
    this.retryOnNetworkError = true,
    this.retryOnServerError = true,
    this.retryOnRateLimit = true,
    this.skipWhenOffline = false,
  });

  /// Standard configuration for most operations
  factory NetworkRetryConfig.standard() => const NetworkRetryConfig();

  /// Fast configuration for excellent network conditions
  factory NetworkRetryConfig.fast() => const NetworkRetryConfig(
    maxAttempts: 2,
    baseRetryDelay: Duration(seconds: 1),
    timeoutRetryDelay: Duration(seconds: 2),
    connectionRetryDelay: Duration(seconds: 1),
  );

  /// Slow configuration for poor network conditions
  factory NetworkRetryConfig.slow() => const NetworkRetryConfig(
    maxAttempts: 5,
    baseRetryDelay: Duration(seconds: 5),
    maxRetryDelay: Duration(minutes: 2),
    timeoutRetryDelay: Duration(seconds: 10),
    connectionRetryDelay: Duration(seconds: 8),
    backoffMultiplier: 1.5,
  );

  /// Configuration for offline scenarios
  factory NetworkRetryConfig.offline() => const NetworkRetryConfig(
    maxAttempts: 1,
    skipWhenOffline: true,
    retryOnTimeout: false,
    retryOnConnectionError: false,
    retryOnNetworkError: false,
  );

  /// Configuration for critical operations
  factory NetworkRetryConfig.critical() => const NetworkRetryConfig(
    maxAttempts: 10,
    baseRetryDelay: Duration(milliseconds: 500),
    maxRetryDelay: Duration(minutes: 5),
    backoffMultiplier: 1.8,
    retryOnTimeout: true,
    retryOnConnectionError: true,
    retryOnNetworkError: true,
    retryOnServerError: true,
    retryOnRateLimit: true,
  );
}

/// Backoff strategies for retry delays
enum BackoffStrategy { exponential, linear, fixed }

/// Result of a network operation with detailed information
class NetworkOperationResult<T> {
  final T? data;
  final Failure? failure;
  final bool isSuccess;
  final int attemptCount;
  final List<NetworkOperationEvent> events;

  const NetworkOperationResult._({
    this.data,
    this.failure,
    required this.isSuccess,
    required this.attemptCount,
    required this.events,
  });

  factory NetworkOperationResult.success(
    T data,
    int attemptCount,
    List<NetworkOperationEvent> events,
  ) {
    return NetworkOperationResult._(
      data: data,
      isSuccess: true,
      attemptCount: attemptCount,
      events: events,
    );
  }

  factory NetworkOperationResult.failure(
    Failure failure,
    int attemptCount,
    List<NetworkOperationEvent> events,
  ) {
    return NetworkOperationResult._(
      failure: failure,
      isSuccess: false,
      attemptCount: attemptCount,
      events: events,
    );
  }
}

/// Events that occur during network operations
abstract class NetworkOperationEvent {
  final int attempt;
  final DateTime timestamp;

  NetworkOperationEvent(this.attempt) : timestamp = DateTime.now();

  factory NetworkOperationEvent.attempting(int attempt) =>
      NetworkOperationAttempting(attempt);

  factory NetworkOperationEvent.succeeded(int attempt) =>
      NetworkOperationSucceeded(attempt);

  factory NetworkOperationEvent.failed(int attempt, Failure failure) =>
      NetworkOperationFailed(attempt, failure);

  factory NetworkOperationEvent.retrying(int attempt, Duration delay) =>
      NetworkOperationRetrying(attempt, delay);

  factory NetworkOperationEvent.skippedOffline(int attempt) =>
      NetworkOperationSkippedOffline(attempt);
}

class NetworkOperationAttempting extends NetworkOperationEvent {
  NetworkOperationAttempting(super.attempt);

  @override
  String toString() => 'Attempting network operation (attempt $attempt)';
}

class NetworkOperationSucceeded extends NetworkOperationEvent {
  NetworkOperationSucceeded(super.attempt);

  @override
  String toString() => 'Network operation succeeded (attempt $attempt)';
}

class NetworkOperationFailed extends NetworkOperationEvent {
  final Failure failure;

  NetworkOperationFailed(super.attempt, this.failure);

  @override
  String toString() =>
      'Network operation failed (attempt $attempt): ${failure.message}';
}

class NetworkOperationRetrying extends NetworkOperationEvent {
  final Duration delay;

  NetworkOperationRetrying(super.attempt, this.delay);

  @override
  String toString() =>
      'Retrying network operation (attempt $attempt) in ${delay.inMilliseconds}ms';
}

class NetworkOperationSkippedOffline extends NetworkOperationEvent {
  NetworkOperationSkippedOffline(super.attempt);

  @override
  String toString() =>
      'Network operation skipped due to offline status (attempt $attempt)';
}
