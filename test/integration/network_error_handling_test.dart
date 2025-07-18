import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

import 'package:crypto_dashboard/core/network/network_error_handler.dart';
import 'package:crypto_dashboard/core/network/network_info.dart';
import 'package:crypto_dashboard/core/network/offline_manager.dart';
import 'package:crypto_dashboard/core/network/offline_detector.dart';
import 'package:crypto_dashboard/core/error/error_handling.dart';

void main() {
  group('Network Error Handling Tests', () {
    late NetworkInfo networkInfo;
    late OfflineManager offlineManager;
    late OfflineDetector offlineDetector;
    late NetworkErrorHandler networkErrorHandler;

    setUp(() {
      networkInfo = NetworkInfoImpl();
      offlineManager = OfflineManager(networkInfo);
      offlineDetector = OfflineDetector();
      networkErrorHandler = NetworkErrorHandler(
        networkInfo,
        offlineManager: offlineManager,
        offlineDetector: offlineDetector,
      );
    });

    tearDown(() {
      networkInfo.dispose();
      offlineManager.dispose();
      offlineDetector.dispose();
    });

    group('Timeout Error Handling', () {
      test('should handle DioException timeout errors correctly', () async {
        // Arrange
        final timeoutException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timeout',
        );

        // Act
        final failure = await networkErrorHandler.handleNetworkException(
          timeoutException,
        );

        // Assert
        expect(failure, isA<TimeoutFailure>());
        expect(failure.message, equals('Connection timeout'));
        expect(failure.details, contains('timeout period'));
      });

      test('should handle receive timeout with enhanced context', () async {
        // Arrange
        final timeoutException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.receiveTimeout,
          message: 'Receive timeout',
        );

        // Act
        final failure = await networkErrorHandler.handleNetworkException(
          timeoutException,
        );

        // Assert
        expect(failure, isA<TimeoutFailure>());
        expect(failure.message, equals('Receive timeout'));
        expect(failure.details, contains('Server took too long'));
      });

      test('should handle TimeoutException with duration context', () async {
        // Arrange
        final timeoutException = TimeoutException(
          message: 'Operation timeout',
          details: 'Custom timeout',
        );
        const timeoutDuration = Duration(seconds: 30);

        // Act
        final failure = await networkErrorHandler.handleTimeoutError(
          timeoutException,
          timeoutDuration,
        );

        // Assert
        expect(failure, isA<TimeoutFailure>());
        expect(failure.message, equals('Request timeout'));
        expect(failure.details, contains('30 seconds'));
      });
    });

    group('Connection Error Handling', () {
      test('should handle DioException connection errors', () async {
        // Arrange
        final connectionException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionError,
          message: 'Connection failed',
        );

        // Act
        final failure = await networkErrorHandler.handleNetworkException(
          connectionException,
        );

        // Assert
        expect(failure, isA<ConnectionFailure>());
        expect(failure.message, equals('Connection failed'));
        expect(failure.details, contains('check your internet connection'));
      });

      test('should handle SocketException with specific error codes', () async {
        // Arrange
        final socketException = SocketException(
          'Connection refused',
          osError: OSError('Connection refused', 61),
        );

        // Act
        final failure = await networkErrorHandler.handleNetworkException(
          socketException,
        );

        // Assert
        expect(failure, isA<ConnectionFailure>());
        expect(failure.message, equals('Connection refused'));
        expect(failure.details, contains('service might be down'));
      });

      test('should handle DNS resolution failures', () async {
        // Arrange
        final socketException = SocketException(
          'No address associated with hostname',
          osError: OSError('No address associated with hostname', 7),
        );

        // Act
        final failure = await networkErrorHandler.handleNetworkException(
          socketException,
        );

        // Assert
        expect(failure, isA<NetworkFailure>());
        expect(failure.message, equals('DNS resolution failed'));
        expect(failure.details, contains('DNS settings'));
      });
    });

    group('HTTP Status Code Handling', () {
      test('should handle rate limit errors (429)', () async {
        // Arrange
        final rateLimitException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 429,
            statusMessage: 'Too Many Requests',
          ),
        );

        // Act
        final failure = await networkErrorHandler.handleNetworkException(
          rateLimitException,
        );

        // Assert
        expect(failure, isA<ApiFailure>());
        expect(failure.message, equals('Rate limit exceeded'));
        expect(failure.errorCode, equals(429));
        expect(failure.details, contains('wait before trying again'));
      });

      test('should handle server errors (500)', () async {
        // Arrange
        final serverErrorException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 500,
            statusMessage: 'Internal Server Error',
          ),
        );

        // Act
        final failure = await networkErrorHandler.handleNetworkException(
          serverErrorException,
        );

        // Assert
        expect(failure, isA<ApiFailure>());
        expect(failure.message, equals('Server error'));
        expect(failure.errorCode, equals(500));
        expect(failure.details, contains('try again later'));
      });

      test('should handle gateway timeout (504)', () async {
        // Arrange
        final gatewayTimeoutException = DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 504,
            statusMessage: 'Gateway Timeout',
          ),
        );

        // Act
        final failure = await networkErrorHandler.handleNetworkException(
          gatewayTimeoutException,
        );

        // Assert
        expect(failure, isA<TimeoutFailure>());
        expect(failure.message, equals('Gateway timeout'));
        expect(failure.errorCode, equals(504));
        expect(failure.details, contains('upstream server'));
      });
    });

    group('Retry Configuration', () {
      test(
        'should create appropriate retry config for different failure types',
        () {
          // Test timeout failure
          final timeoutFailure = TimeoutFailure(message: 'Timeout');
          final timeoutDelay = networkErrorHandler.getNetworkRetryDelay(
            timeoutFailure,
            1,
          );
          expect(timeoutDelay.inSeconds, greaterThanOrEqualTo(5));

          // Test rate limit failure
          final rateLimitFailure = ApiFailure(
            message: 'Rate limit',
            errorCode: 429,
          );
          final rateLimitDelay = networkErrorHandler.getNetworkRetryDelay(
            rateLimitFailure,
            1,
          );
          expect(rateLimitDelay.inSeconds, greaterThanOrEqualTo(10));

          // Test connection failure
          final connectionFailure = ConnectionFailure(
            message: 'Connection failed',
          );
          final connectionDelay = networkErrorHandler.getNetworkRetryDelay(
            connectionFailure,
            1,
          );
          expect(connectionDelay.inSeconds, greaterThanOrEqualTo(2));
        },
      );

      test('should create network retry configurations', () {
        // Test standard config
        final standardConfig = NetworkRetryConfig.standard();
        expect(standardConfig.maxAttempts, equals(3));
        expect(
          standardConfig.baseRetryDelay,
          equals(const Duration(seconds: 2)),
        );
        expect(standardConfig.retryOnTimeout, isTrue);
        expect(standardConfig.retryOnConnectionError, isTrue);

        // Test fast config
        final fastConfig = NetworkRetryConfig.fast();
        expect(fastConfig.maxAttempts, equals(2));
        expect(fastConfig.baseRetryDelay, equals(const Duration(seconds: 1)));

        // Test slow config
        final slowConfig = NetworkRetryConfig.slow();
        expect(slowConfig.maxAttempts, equals(5));
        expect(slowConfig.baseRetryDelay, equals(const Duration(seconds: 5)));

        // Test critical config
        final criticalConfig = NetworkRetryConfig.critical();
        expect(criticalConfig.maxAttempts, equals(10));
        expect(
          criticalConfig.maxRetryDelay,
          equals(const Duration(minutes: 5)),
        );
      });
    });

    group('Enhanced Network Operation', () {
      test('should execute operation with success', () async {
        // Arrange
        var callCount = 0;
        operation() async {
          callCount++;
          return 'success';
        }

        // Act
        final result = await networkErrorHandler.executeWithEnhancedHandling(
          operation,
          config: NetworkRetryConfig.standard(),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, equals('success'));
        expect(result.attemptCount, equals(1));
        expect(callCount, equals(1));
      });

      test('should retry on recoverable failures', () async {
        // Arrange
        var callCount = 0;
        operation() async {
          callCount++;
          if (callCount < 3) {
            throw DioException(
              requestOptions: RequestOptions(path: '/test'),
              type: DioExceptionType.connectionTimeout,
              message: 'Connection timeout',
            );
          }
          return 'success after retries';
        }

        // Act
        final result = await networkErrorHandler.executeWithEnhancedHandling(
          operation,
          config: NetworkRetryConfig.standard(),
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, equals('success after retries'));
        expect(result.attemptCount, equals(3));
        expect(callCount, equals(3));
      });

      test('should fail after max attempts', () async {
        // Arrange
        var callCount = 0;
        operation() async {
          callCount++;
          throw DioException(
            requestOptions: RequestOptions(path: '/test'),
            type: DioExceptionType.connectionTimeout,
            message: 'Persistent timeout',
          );
        }

        // Act
        final result = await networkErrorHandler.executeWithEnhancedHandling(
          operation,
          config: NetworkRetryConfig.standard(),
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.failure, isA<TimeoutFailure>());
        expect(result.attemptCount, equals(3));
        expect(callCount, equals(3));
      });

      test('should emit operation events', () async {
        // Arrange
        final events = <NetworkOperationEvent>[];
        var callCount = 0;
        operation() async {
          callCount++;
          if (callCount < 2) {
            throw DioException(
              requestOptions: RequestOptions(path: '/test'),
              type: DioExceptionType.connectionTimeout,
              message: 'Timeout',
            );
          }
          return 'success';
        }

        // Act
        await networkErrorHandler.executeWithEnhancedHandling(
          operation,
          config: NetworkRetryConfig.standard(),
          onEvent: (event) => events.add(event),
        );

        // Assert
        expect(events.length, greaterThan(2));
        expect(events.first, isA<NetworkOperationAttempting>());
        expect(events.any((e) => e is NetworkOperationFailed), isTrue);
        expect(events.any((e) => e is NetworkOperationRetrying), isTrue);
        expect(events.last, isA<NetworkOperationSucceeded>());
      });
    });

    group('Offline Detection Integration', () {
      test('should determine when to go offline', () {
        // Test network failure
        final networkFailure = NetworkFailure(
          message: 'No internet connection',
          details: 'Check connection',
        );
        expect(networkErrorHandler.shouldGoOffline(networkFailure), isTrue);

        // Test DNS failure
        final dnsFailure = NetworkFailure(
          message: 'DNS resolution failed',
          details: 'DNS error',
        );
        expect(networkErrorHandler.shouldGoOffline(dnsFailure), isTrue);

        // Test API failure (should not go offline)
        final apiFailure = ApiFailure(message: 'Server error', errorCode: 500);
        expect(networkErrorHandler.shouldGoOffline(apiFailure), isFalse);
      });
    });

    group('Adaptive Retry Configuration', () {
      test(
        'should get adaptive retry config based on network quality',
        () async {
          // This test will use the actual network info implementation
          // which may vary based on actual network conditions
          final config = await networkErrorHandler.getAdaptiveRetryConfig();

          // Basic validation that config is created
          expect(config.maxAttempts, greaterThan(0));
          expect(config.baseRetryDelay.inMilliseconds, greaterThan(0));
          expect(
            config.maxRetryDelay.inMilliseconds,
            greaterThan(config.baseRetryDelay.inMilliseconds),
          );
        },
      );
    });
  });
}
