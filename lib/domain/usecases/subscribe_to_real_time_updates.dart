import 'dart:async';

import '../entities/entities.dart';
import '../repositories/cryptocurrency_repository.dart';

/// Use case for subscribing to real-time cryptocurrency updates
///
/// This use case handles:
/// - Periodic polling mechanism for price updates
/// - Volume spike detection logic (>50% increase)
/// - Listing status change detection
///
/// Requirements: 2.1, 3.1, 4.1
class SubscribeToRealTimeUpdates {
  final CryptocurrencyRepository repository;

  const SubscribeToRealTimeUpdates(this.repository);

  /// Volume spike threshold (50% increase)
  static const double volumeSpikeThreshold = 0.5;

  /// Subscribes to real-time updates and returns a stream of cryptocurrency events
  ///
  /// Returns: Stream of CryptocurrencyUpdateEvent objects
  /// The stream includes price updates, volume alerts, and status changes
  Stream<CryptocurrencyUpdateEvent> call() async* {
    StreamController<CryptocurrencyUpdateEvent>? controller;
    StreamSubscription<PriceUpdateEvent>? priceSubscription;
    StreamSubscription<VolumeAlert>? volumeSubscription;
    StreamSubscription<ConnectionStatus>? connectionSubscription;

    try {
      // Start real-time updates in the repository
      await repository.startRealTimeUpdates();

      // Create a stream controller to merge multiple streams
      controller = StreamController<CryptocurrencyUpdateEvent>.broadcast();

      // Subscribe to price updates
      priceSubscription = repository.getPriceUpdates().listen(
        (priceUpdate) {
          if (!controller!.isClosed) {
            controller.add(CryptocurrencyUpdateEvent.priceUpdate(priceUpdate));
          }
        },
        onError: (error) {
          if (!controller!.isClosed) {
            controller.addError(
              SubscribeToRealTimeUpdatesException(
                'Price update stream error: ${error.toString()}',
                SubscribeToRealTimeUpdatesErrorType.priceUpdateError,
                originalException: error,
              ),
            );
          }
        },
        cancelOnError: false,
      );

      // Subscribe to volume alerts
      volumeSubscription = repository.getVolumeAlerts().listen(
        (volumeAlert) {
          // Validate volume spike threshold
          if (_isVolumeSpike(volumeAlert) && !controller!.isClosed) {
            controller.add(CryptocurrencyUpdateEvent.volumeAlert(volumeAlert));
          }
        },
        onError: (error) {
          if (!controller!.isClosed) {
            controller.addError(
              SubscribeToRealTimeUpdatesException(
                'Volume alert stream error: ${error.toString()}',
                SubscribeToRealTimeUpdatesErrorType.volumeAlertError,
                originalException: error,
              ),
            );
          }
        },
        cancelOnError: false,
      );

      // Subscribe to connection status updates
      connectionSubscription = repository.getConnectionStatus().listen(
        (connectionStatus) {
          if (!controller!.isClosed) {
            controller.add(
              CryptocurrencyUpdateEvent.connectionStatus(connectionStatus),
            );
          }
        },
        onError: (error) {
          if (!controller!.isClosed) {
            controller.addError(
              SubscribeToRealTimeUpdatesException(
                'Connection status stream error: ${error.toString()}',
                SubscribeToRealTimeUpdatesErrorType.connectionError,
                originalException: error,
              ),
            );
          }
        },
        cancelOnError: false,
      );

      // Handle stream cleanup with proper resource disposal
      controller.onCancel = () async {
        try {
          // Cancel all subscriptions in parallel for faster cleanup
          await Future.wait([
            priceSubscription?.cancel() ?? Future.value(),
            volumeSubscription?.cancel() ?? Future.value(),
            connectionSubscription?.cancel() ?? Future.value(),
          ]);

          // Stop repository updates
          await repository.stopRealTimeUpdates();
        } catch (e) {
          // Log error but don't throw during cleanup
          // In production, use proper logging
          // print('Warning: Error during stream cleanup: $e');
        }
      };

      // Yield events from the merged stream
      yield* controller.stream;
    } catch (e) {
      // Ensure cleanup on error
      await _cleanupResources(
        controller,
        priceSubscription,
        volumeSubscription,
        connectionSubscription,
      );
      rethrow;
    }
  }

  /// Helper method to clean up resources
  Future<void> _cleanupResources(
    StreamController<CryptocurrencyUpdateEvent>? controller,
    StreamSubscription<PriceUpdateEvent>? priceSubscription,
    StreamSubscription<VolumeAlert>? volumeSubscription,
    StreamSubscription<ConnectionStatus>? connectionSubscription,
  ) async {
    try {
      // Cancel all subscriptions
      await Future.wait([
        priceSubscription?.cancel() ?? Future.value(),
        volumeSubscription?.cancel() ?? Future.value(),
        connectionSubscription?.cancel() ?? Future.value(),
      ]);

      // Close controller if not already closed
      if (controller != null && !controller.isClosed) {
        await controller.close();
      }

      // Stop repository updates
      await repository.stopRealTimeUpdates();
    } catch (e) {
      // Log error but don't throw during cleanup
      // In production, use proper logging
      // print('Warning: Error during resource cleanup: $e');
    }
  }

  /// Checks if a volume alert represents a significant spike (>50% increase)
  bool _isVolumeSpike(VolumeAlert volumeAlert) {
    if (volumeAlert.previousVolume <= 0) {
      return false; // Cannot calculate percentage if previous volume is 0
    }

    final volumeIncrease =
        volumeAlert.currentVolume - volumeAlert.previousVolume;
    final percentageIncrease = volumeIncrease / volumeAlert.previousVolume;

    return percentageIncrease >= volumeSpikeThreshold;
  }
}

/// Union type for different cryptocurrency update events
class CryptocurrencyUpdateEvent {
  final CryptocurrencyUpdateEventType type;
  final PriceUpdateEvent? priceUpdate;
  final VolumeAlert? volumeAlert;
  final ConnectionStatus? connectionStatus;

  const CryptocurrencyUpdateEvent._({
    required this.type,
    this.priceUpdate,
    this.volumeAlert,
    this.connectionStatus,
  });

  /// Creates a price update event
  factory CryptocurrencyUpdateEvent.priceUpdate(PriceUpdateEvent priceUpdate) {
    return CryptocurrencyUpdateEvent._(
      type: CryptocurrencyUpdateEventType.priceUpdate,
      priceUpdate: priceUpdate,
    );
  }

  /// Creates a volume alert event
  factory CryptocurrencyUpdateEvent.volumeAlert(VolumeAlert volumeAlert) {
    return CryptocurrencyUpdateEvent._(
      type: CryptocurrencyUpdateEventType.volumeAlert,
      volumeAlert: volumeAlert,
    );
  }

  /// Creates a connection status event
  factory CryptocurrencyUpdateEvent.connectionStatus(
    ConnectionStatus connectionStatus,
  ) {
    return CryptocurrencyUpdateEvent._(
      type: CryptocurrencyUpdateEventType.connectionStatus,
      connectionStatus: connectionStatus,
    );
  }

  @override
  String toString() {
    switch (type) {
      case CryptocurrencyUpdateEventType.priceUpdate:
        return 'CryptocurrencyUpdateEvent.priceUpdate($priceUpdate)';
      case CryptocurrencyUpdateEventType.volumeAlert:
        return 'CryptocurrencyUpdateEvent.volumeAlert($volumeAlert)';
      case CryptocurrencyUpdateEventType.connectionStatus:
        return 'CryptocurrencyUpdateEvent.connectionStatus($connectionStatus)';
    }
  }
}

/// Types of cryptocurrency update events
enum CryptocurrencyUpdateEventType {
  priceUpdate,
  volumeAlert,
  connectionStatus,
}

/// Exception thrown by SubscribeToRealTimeUpdates use case
class SubscribeToRealTimeUpdatesException implements Exception {
  final String message;
  final SubscribeToRealTimeUpdatesErrorType errorType;
  final Object? originalException;

  const SubscribeToRealTimeUpdatesException(
    this.message,
    this.errorType, {
    this.originalException,
  });

  @override
  String toString() => 'SubscribeToRealTimeUpdatesException: $message';
}

/// Types of errors that can occur in SubscribeToRealTimeUpdates use case
enum SubscribeToRealTimeUpdatesErrorType {
  /// Price update stream error
  priceUpdateError,

  /// Volume alert stream error
  volumeAlertError,

  /// Connection status error
  connectionError,

  /// General subscription error
  subscriptionError,
}
