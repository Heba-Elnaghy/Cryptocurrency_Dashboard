import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final String? details;
  final int? errorCode;

  const Failure({required this.message, this.details, this.errorCode});

  @override
  List<Object?> get props => [message, details, errorCode];
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.details,
    super.errorCode,
  });
}

/// API-related failures
class ApiFailure extends Failure {
  const ApiFailure({required super.message, super.details, super.errorCode});
}

/// Data parsing failures
class DataFailure extends Failure {
  const DataFailure({required super.message, super.details, super.errorCode});
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.details, super.errorCode});
}

/// Unknown/unexpected failures
class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.details,
    super.errorCode,
  });
}

/// Connection-related failures
class ConnectionFailure extends Failure {
  const ConnectionFailure({
    required super.message,
    super.details,
    super.errorCode,
  });
}

/// Timeout-related failures
class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required super.message,
    super.details,
    super.errorCode,
  });
}
