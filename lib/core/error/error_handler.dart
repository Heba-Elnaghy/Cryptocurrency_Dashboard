import 'dart:io';
import 'package:dio/dio.dart';
import 'failures.dart';
import 'exceptions.dart';

/// Comprehensive error handler for the application
class ErrorHandler {
  /// Converts exceptions to user-friendly failures
  static Failure handleException(Exception exception) {
    if (exception is DioException) {
      return _handleDioException(exception);
    } else if (exception is AppException) {
      return _handleAppException(exception);
    } else if (exception is SocketException) {
      return const NetworkFailure(
        message: 'No internet connection',
        details: 'Please check your network connection and try again',
      );
    } else if (exception is FormatException) {
      return DataFailure(
        message: 'Invalid data format',
        details: exception.message,
      );
    } else {
      return UnknownFailure(
        message: 'An unexpected error occurred',
        details: exception.toString(),
      );
    }
  }

  /// Handles Dio-specific exceptions
  static Failure _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
        return const TimeoutFailure(
          message: 'Connection timeout',
          details: 'The request took too long to connect. Please try again.',
        );
      case DioExceptionType.sendTimeout:
        return const TimeoutFailure(
          message: 'Send timeout',
          details: 'The request took too long to send. Please try again.',
        );
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure(
          message: 'Receive timeout',
          details: 'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.badResponse:
        return _handleBadResponse(exception);
      case DioExceptionType.cancel:
        return const NetworkFailure(
          message: 'Request cancelled',
          details: 'The request was cancelled',
        );
      case DioExceptionType.connectionError:
        return const ConnectionFailure(
          message: 'Connection error',
          details:
              'Unable to connect to the server. Please check your internet connection.',
        );
      case DioExceptionType.badCertificate:
        return const NetworkFailure(
          message: 'Security error',
          details: 'SSL certificate verification failed',
        );
      case DioExceptionType.unknown:
      return NetworkFailure(
          message: 'Network error',
          details: exception.message ?? 'An unknown network error occurred',
        );
    }
  }

  /// Handles bad HTTP response codes
  static Failure _handleBadResponse(DioException exception) {
    final statusCode = exception.response?.statusCode;

    switch (statusCode) {
      case 400:
        return const ApiFailure(
          message: 'Bad request',
          details: 'The request was invalid. Please try again.',
          errorCode: 400,
        );
      case 401:
        return const ApiFailure(
          message: 'Unauthorized',
          details: 'Authentication failed. Please check your credentials.',
          errorCode: 401,
        );
      case 403:
        return const ApiFailure(
          message: 'Forbidden',
          details: 'You do not have permission to access this resource.',
          errorCode: 403,
        );
      case 404:
        return const ApiFailure(
          message: 'Not found',
          details: 'The requested resource was not found.',
          errorCode: 404,
        );
      case 429:
        return const ApiFailure(
          message: 'Too many requests',
          details: 'Rate limit exceeded. Please wait before trying again.',
          errorCode: 429,
        );
      case 500:
        return const ApiFailure(
          message: 'Server error',
          details: 'The server encountered an error. Please try again later.',
          errorCode: 500,
        );
      case 502:
        return const ApiFailure(
          message: 'Bad gateway',
          details:
              'The server is temporarily unavailable. Please try again later.',
          errorCode: 502,
        );
      case 503:
        return const ApiFailure(
          message: 'Service unavailable',
          details:
              'The service is temporarily unavailable. Please try again later.',
          errorCode: 503,
        );
      default:
        return ApiFailure(
          message: 'Server error',
          details: 'Server returned status code: $statusCode',
          errorCode: statusCode,
        );
    }
  }

  /// Handles application-specific exceptions
  static Failure _handleAppException(AppException exception) {
    if (exception is NetworkException) {
      return NetworkFailure(
        message: exception.message,
        details: exception.details,
        errorCode: exception.errorCode,
      );
    } else if (exception is ApiException) {
      return ApiFailure(
        message: exception.message,
        details: exception.details,
        errorCode: exception.errorCode,
      );
    } else if (exception is DataException) {
      return DataFailure(
        message: exception.message,
        details: exception.details,
        errorCode: exception.errorCode,
      );
    } else if (exception is CacheException) {
      return CacheFailure(
        message: exception.message,
        details: exception.details,
        errorCode: exception.errorCode,
      );
    } else if (exception is ConnectionException) {
      return ConnectionFailure(
        message: exception.message,
        details: exception.details,
        errorCode: exception.errorCode,
      );
    } else if (exception is TimeoutException) {
      return TimeoutFailure(
        message: exception.message,
        details: exception.details,
        errorCode: exception.errorCode,
      );
    } else {
      return UnknownFailure(
        message: exception.message,
        details: exception.details,
        errorCode: exception.errorCode,
      );
    }
  }

  /// Gets user-friendly error message for display
  static String getUserFriendlyMessage(Failure failure) {
    return failure.message;
  }

  /// Gets detailed error message for debugging
  static String getDetailedMessage(Failure failure) {
    final buffer = StringBuffer(failure.message);

    if (failure.details != null) {
      buffer.write('\nDetails: ${failure.details}');
    }

    if (failure.errorCode != null) {
      buffer.write('\nError Code: ${failure.errorCode}');
    }

    return buffer.toString();
  }

  /// Determines if an error is recoverable
  static bool isRecoverable(Failure failure) {
    return failure is NetworkFailure ||
        failure is TimeoutFailure ||
        failure is ConnectionFailure ||
        (failure is ApiFailure && _isRecoverableApiError(failure.errorCode));
  }

  /// Checks if an API error is recoverable
  static bool _isRecoverableApiError(int? statusCode) {
    if (statusCode == null) return false;

    // Recoverable status codes
    return statusCode == 429 || // Rate limit
        statusCode == 500 || // Internal server error
        statusCode == 502 || // Bad gateway
        statusCode == 503 || // Service unavailable
        statusCode == 504; // Gateway timeout
  }

  /// Gets retry delay based on failure type and attempt count
  static Duration getRetryDelay(Failure failure, int attemptCount) {
    // Exponential backoff with jitter
    final baseDelay = Duration(seconds: 2);
    final exponentialDelay = Duration(
      milliseconds: (baseDelay.inMilliseconds * (1 << attemptCount)).clamp(
        baseDelay.inMilliseconds,
        30000, // Max 30 seconds
      ),
    );

    // Add jitter to prevent thundering herd
    final jitter = Duration(
      milliseconds: (exponentialDelay.inMilliseconds * 0.1).round(),
    );

    return exponentialDelay + jitter;
  }

  /// Gets user-friendly error message with recovery suggestions
  static String getUserFriendlyMessageWithRecovery(Failure failure) {
    final message = StringBuffer(failure.message);

    // Add recovery suggestions based on failure type
    if (failure is NetworkFailure || failure is ConnectionFailure) {
      message.write('\n\nSuggestions:');
      message.write('\n• Check your internet connection');
      message.write('\n• Try again in a few moments');
      message.write('\n• Switch to a different network if available');
    } else if (failure is TimeoutFailure) {
      message.write('\n\nSuggestions:');
      message.write('\n• Check your internet speed');
      message.write('\n• Try again with a better connection');
      message.write('\n• The server might be busy, please wait');
    } else if (failure is ApiFailure) {
      final statusCode = failure.errorCode;
      if (statusCode == 429) {
        message.write(
          '\n\nSuggestion: Please wait a moment before trying again',
        );
      } else if (statusCode != null && statusCode >= 500) {
        message.write(
          '\n\nSuggestion: The server is experiencing issues, please try again later',
        );
      }
    } else if (failure is DataFailure) {
      message.write(
        '\n\nSuggestion: Please refresh the data or restart the app',
      );
    }

    return message.toString();
  }

  /// Gets recovery actions for a failure
  static List<RecoveryAction> getRecoveryActions(Failure failure) {
    final actions = <RecoveryAction>[];

    // Always offer retry for recoverable errors
    if (isRecoverable(failure)) {
      actions.add(RecoveryAction.retry());
    }

    // Specific actions based on failure type
    if (failure is NetworkFailure || failure is ConnectionFailure) {
      actions.add(RecoveryAction.checkConnection());
      actions.add(RecoveryAction.switchNetwork());
    } else if (failure is TimeoutFailure) {
      actions.add(RecoveryAction.waitAndRetry());
    } else if (failure is ApiFailure && failure.errorCode == 429) {
      actions.add(RecoveryAction.waitForRateLimit());
    } else if (failure is DataFailure) {
      actions.add(RecoveryAction.refreshData());
    }

    // Always offer option to report issue
    actions.add(RecoveryAction.reportIssue());

    return actions;
  }

  /// Gets severity level of a failure
  static ErrorSeverity getSeverity(Failure failure) {
    if (failure is NetworkFailure ||
        failure is ConnectionFailure ||
        failure is TimeoutFailure) {
      return ErrorSeverity.warning;
    } else if (failure is ApiFailure) {
      final statusCode = failure.errorCode;
      if (statusCode != null && statusCode >= 500) {
        return ErrorSeverity.error;
      } else if (statusCode == 429) {
        return ErrorSeverity.warning;
      } else if (statusCode != null && statusCode >= 400) {
        return ErrorSeverity.error;
      }
    } else if (failure is DataFailure) {
      return ErrorSeverity.warning;
    }

    return ErrorSeverity.critical;
  }
}

/// Represents a recovery action that can be taken
class RecoveryAction {
  final String label;
  final String description;
  final RecoveryActionType type;
  final VoidCallback? action;

  const RecoveryAction({
    required this.label,
    required this.description,
    required this.type,
    this.action,
  });

  factory RecoveryAction.retry() => const RecoveryAction(
    label: 'Retry',
    description: 'Try the operation again',
    type: RecoveryActionType.retry,
  );

  factory RecoveryAction.checkConnection() => const RecoveryAction(
    label: 'Check Connection',
    description: 'Verify your internet connection',
    type: RecoveryActionType.checkConnection,
  );

  factory RecoveryAction.switchNetwork() => const RecoveryAction(
    label: 'Switch Network',
    description: 'Try a different network connection',
    type: RecoveryActionType.switchNetwork,
  );

  factory RecoveryAction.waitAndRetry() => const RecoveryAction(
    label: 'Wait & Retry',
    description: 'Wait a moment and try again',
    type: RecoveryActionType.waitAndRetry,
  );

  factory RecoveryAction.waitForRateLimit() => const RecoveryAction(
    label: 'Wait',
    description: 'Wait for rate limit to reset',
    type: RecoveryActionType.waitForRateLimit,
  );

  factory RecoveryAction.refreshData() => const RecoveryAction(
    label: 'Refresh',
    description: 'Refresh the data',
    type: RecoveryActionType.refreshData,
  );

  factory RecoveryAction.reportIssue() => const RecoveryAction(
    label: 'Report Issue',
    description: 'Report this problem',
    type: RecoveryActionType.reportIssue,
  );
}

/// Types of recovery actions
enum RecoveryActionType {
  retry,
  checkConnection,
  switchNetwork,
  waitAndRetry,
  waitForRateLimit,
  refreshData,
  reportIssue,
}

/// Error severity levels
enum ErrorSeverity { info, warning, error, critical }

/// Callback type for recovery actions
typedef VoidCallback = void Function();
