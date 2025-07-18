/// Base class for all exceptions in the application
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final int? errorCode;

  const AppException({required this.message, this.details, this.errorCode});

  @override
  String toString() =>
      'AppException: $message${details != null ? ' - $details' : ''}';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.details,
    super.errorCode,
  });
}

/// API-related exceptions
class ApiException extends AppException {
  const ApiException({required super.message, super.details, super.errorCode});
}

/// Data parsing exceptions
class DataException extends AppException {
  const DataException({required super.message, super.details, super.errorCode});
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.details,
    super.errorCode,
  });
}

/// Connection-related exceptions
class ConnectionException extends AppException {
  const ConnectionException({
    required super.message,
    super.details,
    super.errorCode,
  });
}

/// Timeout-related exceptions
class TimeoutException extends AppException {
  const TimeoutException({
    required super.message,
    super.details,
    super.errorCode,
  });
}
