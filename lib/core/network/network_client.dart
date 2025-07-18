import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../error/error_handling.dart';
import 'network_info.dart';
import 'network_error_handler.dart';
import 'offline_manager.dart';
import 'offline_detector.dart';

/// Configuration for network client
class NetworkClientConfig {
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final int maxRetries;
  final Duration retryDelay;
  final double retryBackoffMultiplier;
  final bool requiresNetwork;
  final List<int> retryStatusCodes;

  const NetworkClientConfig({
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.retryBackoffMultiplier = 2.0,
    this.requiresNetwork = true,
    this.retryStatusCodes = const [408, 429, 500, 502, 503, 504],
  });

  /// Configuration for API calls
  static const api = NetworkClientConfig(
    connectTimeout: Duration(seconds: 15),
    receiveTimeout: Duration(seconds: 30),
    maxRetries: 3,
    retryDelay: Duration(seconds: 2),
  );

  /// Configuration for real-time updates
  static const realTime = NetworkClientConfig(
    connectTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 10),
    maxRetries: 5,
    retryDelay: Duration(seconds: 1),
    retryBackoffMultiplier: 1.5,
  );

  /// Configuration for critical operations
  static const critical = NetworkClientConfig(
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 60),
    maxRetries: 10,
    retryDelay: Duration(milliseconds: 500),
    retryBackoffMultiplier: 1.8,
  );
}

/// Network-aware HTTP client with automatic retry and error handling
class NetworkClient {
  final Dio _dio;
  final NetworkInfo _networkInfo;
  final NetworkClientConfig _config;
  final NetworkErrorHandler _errorHandler;
  final StreamController<NetworkClientEvent> _eventController =
      StreamController<NetworkClientEvent>.broadcast();

  NetworkClient(
    this._networkInfo, {
    NetworkClientConfig config = NetworkClientConfig.api,
    String? baseUrl,
    Map<String, String>? headers,
    OfflineManager? offlineManager,
    OfflineDetector? offlineDetector,
  }) : _config = config,
       _dio = Dio(),
       _errorHandler = NetworkErrorHandler(
         _networkInfo,
         offlineManager: offlineManager,
         offlineDetector: offlineDetector,
       ) {
    _setupDio(baseUrl, headers);
    _setupInterceptors();
  }

  /// Stream of network client events
  Stream<NetworkClientEvent> get events => _eventController.stream;

  /// Performs a GET request with network awareness and retry logic
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    NetworkClientConfig? config,
  }) async {
    return _executeWithRetry(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'GET $path',
      config: config,
    );
  }

  /// Performs a POST request with network awareness and retry logic
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    NetworkClientConfig? config,
  }) async {
    return _executeWithRetry(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'POST $path',
      config: config,
    );
  }

  /// Performs a PUT request with network awareness and retry logic
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    NetworkClientConfig? config,
  }) async {
    return _executeWithRetry(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'PUT $path',
      config: config,
    );
  }

  /// Performs a DELETE request with network awareness and retry logic
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    NetworkClientConfig? config,
  }) async {
    return _executeWithRetry(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      'DELETE $path',
      config: config,
    );
  }

  /// Executes a request with retry logic and network awareness
  Future<Response<T>> _executeWithRetry<T>(
    Future<Response<T>> Function() request,
    String operationName, {
    NetworkClientConfig? config,
  }) async {
    final effectiveConfig = config ?? _config;

    // Convert NetworkClientConfig to NetworkRetryConfig
    final networkRetryConfig = NetworkRetryConfig(
      maxAttempts: effectiveConfig.maxRetries,
      baseRetryDelay: effectiveConfig.retryDelay,
      backoffMultiplier: effectiveConfig.retryBackoffMultiplier,
      retryOnTimeout: true,
      retryOnConnectionError: true,
      retryOnNetworkError: true,
      retryOnServerError: true,
      retryOnRateLimit: true,
      skipWhenOffline: effectiveConfig.requiresNetwork,
    );

    // Use enhanced network error handler
    final result = await _errorHandler.executeWithEnhancedHandling<Response<T>>(
      () async {
        // Check network connectivity if required
        if (effectiveConfig.requiresNetwork) {
          final isConnected = await _networkInfo.isConnected;
          if (!isConnected) {
            throw const NetworkException(
              message: 'No internet connection',
              details: 'Please check your network connection and try again',
            );
          }
        }

        return await request();
      },
      config: networkRetryConfig,
      onEvent: (event) {
        // Convert NetworkOperationEvent to NetworkClientEvent
        if (event is NetworkOperationAttempting) {
          _emitEvent(
            NetworkClientEvent.attempting(operationName, event.attempt),
          );
        } else if (event is NetworkOperationSucceeded) {
          _emitEvent(
            NetworkClientEvent.succeeded(
              operationName,
              event.attempt,
              200, // Default status code since we don't have it in the event
            ),
          );
        } else if (event is NetworkOperationFailed) {
          _emitEvent(
            NetworkClientEvent.failed(
              operationName,
              event.attempt,
              event.failure,
            ),
          );
        } else if (event is NetworkOperationRetrying) {
          _emitEvent(
            NetworkClientEvent.retrying(
              operationName,
              event.attempt,
              event.delay,
            ),
          );
        }
      },
    );

    if (result.isSuccess) {
      return result.data!;
    } else {
      // Convert failure back to exception for consistency
      final failure = result.failure!;
      if (failure is NetworkFailure) {
        throw NetworkException(
          message: failure.message,
          details: failure.details,
          errorCode: failure.errorCode,
        );
      } else if (failure is TimeoutFailure) {
        throw TimeoutException(
          message: failure.message,
          details: failure.details,
          errorCode: failure.errorCode,
        );
      } else if (failure is ConnectionFailure) {
        throw ConnectionException(
          message: failure.message,
          details: failure.details,
          errorCode: failure.errorCode,
        );
      } else if (failure is ApiFailure) {
        throw ApiException(
          message: failure.message,
          details: failure.details,
          errorCode: failure.errorCode,
        );
      } else {
        throw NetworkException(
          message: failure.message,
          details: failure.details,
          errorCode: failure.errorCode,
        );
      }
    }
  }



  /// Sets up Dio configuration
  void _setupDio(String? baseUrl, Map<String, String>? headers) {
    _dio.options = BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: _config.connectTimeout,
      receiveTimeout: _config.receiveTimeout,
      sendTimeout: _config.sendTimeout,
      headers: headers,
      validateStatus: (status) => status != null && status < 500,
    );
  }

  /// Sets up Dio interceptors
  void _setupInterceptors() {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    // Add network quality interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add network quality headers
          final connectionInfo = await _networkInfo.getConnectionInfo();
          options.headers['X-Network-Quality'] = connectionInfo.quality.name;
          if (connectionInfo.latency != null) {
            options.headers['X-Network-Latency'] = connectionInfo
                .latency!
                .inMilliseconds
                .toString();
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // Convert DioException to our custom exceptions
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                type: error.type,
                message: 'Request timeout - please check your connection',
                error: TimeoutException(
                  message: 'Request timeout',
                  details: 'The request took too long to complete',
                ),
              ),
            );
          } else if (error.type == DioExceptionType.connectionError) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                type: error.type,
                message: 'Connection error - please check your internet',
                error: ConnectionException(
                  message: 'Connection failed',
                  details: 'Unable to connect to the server',
                ),
              ),
            );
          } else {
            handler.next(error);
          }
        },
      ),
    );
  }

  /// Emits a network client event
  void _emitEvent(NetworkClientEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Gets current network connection info
  Future<NetworkConnectionInfo> getConnectionInfo() {
    return _networkInfo.getConnectionInfo();
  }

  /// Checks if network is available
  Future<bool> get isNetworkAvailable => _networkInfo.isConnected;

  /// Disposes the client
  void dispose() {
    _dio.close();
    _eventController.close();
  }
}

/// Events emitted by the network client
abstract class NetworkClientEvent {
  final String operation;
  final DateTime timestamp;

  NetworkClientEvent(this.operation) : timestamp = DateTime.now();

  factory NetworkClientEvent.attempting(String operation, int attempt) =>
      NetworkClientAttempting(operation, attempt);

  factory NetworkClientEvent.succeeded(
    String operation,
    int attempts,
    int statusCode,
  ) => NetworkClientSucceeded(operation, attempts, statusCode);

  factory NetworkClientEvent.failed(
    String operation,
    int attempt,
    Failure failure,
  ) => NetworkClientFailed(operation, attempt, failure);

  factory NetworkClientEvent.retrying(
    String operation,
    int attempt,
    Duration delay,
  ) => NetworkClientRetrying(operation, attempt, delay);
}

class NetworkClientAttempting extends NetworkClientEvent {
  final int attempt;

  NetworkClientAttempting(super.operation, this.attempt);

  @override
  String toString() => 'Attempting $operation (attempt $attempt)';
}

class NetworkClientSucceeded extends NetworkClientEvent {
  final int attempts;
  final int statusCode;

  NetworkClientSucceeded(super.operation, this.attempts, this.statusCode);

  @override
  String toString() =>
      'Succeeded $operation (attempts: $attempts, status: $statusCode)';
}

class NetworkClientFailed extends NetworkClientEvent {
  final int attempt;
  final Failure failure;

  NetworkClientFailed(super.operation, this.attempt, this.failure);

  @override
  String toString() =>
      'Failed $operation (attempt $attempt): ${failure.message}';
}

class NetworkClientRetrying extends NetworkClientEvent {
  final int attempt;
  final Duration delay;

  NetworkClientRetrying(super.operation, this.attempt, this.delay);

  @override
  String toString() =>
      'Retrying $operation (attempt $attempt) in ${delay.inMilliseconds}ms';
}
