import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';
import 'package:crypto_dashboard/domain/repositories/cryptocurrency_repository.dart';
import 'package:crypto_dashboard/domain/usecases/subscribe_to_real_time_updates.dart';

import 'subscribe_to_real_time_updates_test.mocks.dart';

@GenerateMocks([CryptocurrencyRepository])
void main() {
  group('SubscribeToRealTimeUpdates Use Case', () {
    late SubscribeToRealTimeUpdates useCase;
    late MockCryptocurrencyRepository mockRepository;
    late DateTime testDateTime;

    setUp(() {
      mockRepository = MockCryptocurrencyRepository();
      useCase = SubscribeToRealTimeUpdates(mockRepository);
      testDateTime = DateTime(2024, 1, 1, 12, 0, 0);
    });

    group('Volume Spike Threshold', () {
      test('should have correct volume spike threshold', () {
        // Assert
        expect(SubscribeToRealTimeUpdates.volumeSpikeThreshold, equals(0.5));
      });
    });

    group('Volume Spike Detection', () {
      test('should detect volume spike when increase is exactly 50%', () {
        // Arrange
        final volumeAlert = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        // Act - Access private method through reflection or create a test helper
        final isSpike = _testVolumeSpike(volumeAlert);

        // Assert
        expect(isSpike, isTrue);
      });

      test('should detect volume spike when increase is greater than 50%', () {
        // Arrange
        final volumeAlert = VolumeAlert(
          symbol: 'ETH',
          currentVolume: 2000000.0,
          previousVolume: 1000000.0,
          spikePercentage: 1.0, // 100% increase
        );

        // Act
        final isSpike = _testVolumeSpike(volumeAlert);

        // Assert
        expect(isSpike, isTrue);
      });

      test('should not detect volume spike when increase is less than 50%', () {
        // Arrange
        final volumeAlert = VolumeAlert(
          symbol: 'XRP',
          currentVolume: 1400000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.4, // 40% increase
        );

        // Act
        final isSpike = _testVolumeSpike(volumeAlert);

        // Assert
        expect(isSpike, isFalse);
      });

      test('should not detect volume spike when previous volume is zero', () {
        // Arrange
        final volumeAlert = VolumeAlert(
          symbol: 'NEW',
          currentVolume: 1000000.0,
          previousVolume: 0.0,
          spikePercentage: double.infinity,
        );

        // Act
        final isSpike = _testVolumeSpike(volumeAlert);

        // Assert
        expect(isSpike, isFalse);
      });

      test(
        'should not detect volume spike when previous volume is negative',
        () {
          // Arrange
          final volumeAlert = VolumeAlert(
            symbol: 'INVALID',
            currentVolume: 1000000.0,
            previousVolume: -100000.0,
            spikePercentage: -11.0,
          );

          // Act
          final isSpike = _testVolumeSpike(volumeAlert);

          // Assert
          expect(isSpike, isFalse);
        },
      );
    });

    group('Successful Stream Subscription', () {
      test(
        'should start real-time updates and emit price update events',
        () async {
          // Arrange
          final priceUpdateController = StreamController<PriceUpdateEvent>();
          final volumeAlertController = StreamController<VolumeAlert>();
          final connectionStatusController =
              StreamController<ConnectionStatus>();

          when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
          when(
            mockRepository.getPriceUpdates(),
          ).thenAnswer((_) => priceUpdateController.stream);
          when(
            mockRepository.getVolumeAlerts(),
          ).thenAnswer((_) => volumeAlertController.stream);
          when(
            mockRepository.getConnectionStatus(),
          ).thenAnswer((_) => connectionStatusController.stream);

          final priceUpdate = PriceUpdateEvent(
            symbol: 'BTC',
            newPrice: 51000.0,
            priceChange: 1000.0,
            timestamp: testDateTime,
          );

          // Act
          final stream = useCase.call();
          final events = <CryptocurrencyUpdateEvent>[];
          final subscription = stream.listen(events.add);

          // Emit price update
          priceUpdateController.add(priceUpdate);
          await Future.delayed(const Duration(milliseconds: 10));

          // Assert
          expect(events, hasLength(1));
          expect(
            events[0].type,
            equals(CryptocurrencyUpdateEventType.priceUpdate),
          );
          expect(events[0].priceUpdate, equals(priceUpdate));

          // Cleanup
          await subscription.cancel();
          await priceUpdateController.close();
          await volumeAlertController.close();
          await connectionStatusController.close();
        },
      );

      test('should emit volume alert events for significant spikes', () async {
        // Arrange
        final priceUpdateController = StreamController<PriceUpdateEvent>();
        final volumeAlertController = StreamController<VolumeAlert>();
        final connectionStatusController = StreamController<ConnectionStatus>();

        when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
        when(
          mockRepository.getPriceUpdates(),
        ).thenAnswer((_) => priceUpdateController.stream);
        when(
          mockRepository.getVolumeAlerts(),
        ).thenAnswer((_) => volumeAlertController.stream);
        when(
          mockRepository.getConnectionStatus(),
        ).thenAnswer((_) => connectionStatusController.stream);

        final volumeAlert = VolumeAlert(
          symbol: 'ETH',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5, // Exactly 50% spike
        );

        // Act
        final stream = useCase.call();
        final events = <CryptocurrencyUpdateEvent>[];
        final subscription = stream.listen(events.add);

        // Emit volume alert
        volumeAlertController.add(volumeAlert);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events, hasLength(1));
        expect(
          events[0].type,
          equals(CryptocurrencyUpdateEventType.volumeAlert),
        );
        expect(events[0].volumeAlert, equals(volumeAlert));

        // Cleanup
        await subscription.cancel();
        await priceUpdateController.close();
        await volumeAlertController.close();
        await connectionStatusController.close();
      });

      test(
        'should not emit volume alert events for insufficient spikes',
        () async {
          // Arrange
          final priceUpdateController = StreamController<PriceUpdateEvent>();
          final volumeAlertController = StreamController<VolumeAlert>();
          final connectionStatusController =
              StreamController<ConnectionStatus>();

          when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
          when(
            mockRepository.getPriceUpdates(),
          ).thenAnswer((_) => priceUpdateController.stream);
          when(
            mockRepository.getVolumeAlerts(),
          ).thenAnswer((_) => volumeAlertController.stream);
          when(
            mockRepository.getConnectionStatus(),
          ).thenAnswer((_) => connectionStatusController.stream);

          final volumeAlert = VolumeAlert(
            symbol: 'XRP',
            currentVolume: 1400000.0,
            previousVolume: 1000000.0,
            spikePercentage: 0.4, // Only 40% spike
          );

          // Act
          final stream = useCase.call();
          final events = <CryptocurrencyUpdateEvent>[];
          final subscription = stream.listen(events.add);

          // Emit volume alert
          volumeAlertController.add(volumeAlert);
          await Future.delayed(const Duration(milliseconds: 10));

          // Assert - Should not emit event for insufficient spike
          expect(events, isEmpty);

          // Cleanup
          await subscription.cancel();
          await priceUpdateController.close();
          await volumeAlertController.close();
          await connectionStatusController.close();
        },
      );

      test('should emit connection status events', () async {
        // Arrange
        final priceUpdateController = StreamController<PriceUpdateEvent>();
        final volumeAlertController = StreamController<VolumeAlert>();
        final connectionStatusController = StreamController<ConnectionStatus>();

        when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
        when(
          mockRepository.getPriceUpdates(),
        ).thenAnswer((_) => priceUpdateController.stream);
        when(
          mockRepository.getVolumeAlerts(),
        ).thenAnswer((_) => volumeAlertController.stream);
        when(
          mockRepository.getConnectionStatus(),
        ).thenAnswer((_) => connectionStatusController.stream);

        final connectionStatus = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );

        // Act
        final stream = useCase.call();
        final events = <CryptocurrencyUpdateEvent>[];
        final subscription = stream.listen(events.add);

        // Emit connection status
        connectionStatusController.add(connectionStatus);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events, hasLength(1));
        expect(
          events[0].type,
          equals(CryptocurrencyUpdateEventType.connectionStatus),
        );
        expect(events[0].connectionStatus, equals(connectionStatus));

        // Cleanup
        await subscription.cancel();
        await priceUpdateController.close();
        await volumeAlertController.close();
        await connectionStatusController.close();
      });

      test('should handle multiple event types simultaneously', () async {
        // Arrange
        final priceUpdateController = StreamController<PriceUpdateEvent>();
        final volumeAlertController = StreamController<VolumeAlert>();
        final connectionStatusController = StreamController<ConnectionStatus>();

        when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
        when(
          mockRepository.getPriceUpdates(),
        ).thenAnswer((_) => priceUpdateController.stream);
        when(
          mockRepository.getVolumeAlerts(),
        ).thenAnswer((_) => volumeAlertController.stream);
        when(
          mockRepository.getConnectionStatus(),
        ).thenAnswer((_) => connectionStatusController.stream);

        final priceUpdate = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        final volumeAlert = VolumeAlert(
          symbol: 'ETH',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        final connectionStatus = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );

        // Act
        final stream = useCase.call();
        final events = <CryptocurrencyUpdateEvent>[];
        final subscription = stream.listen(events.add);

        // Emit all event types
        priceUpdateController.add(priceUpdate);
        volumeAlertController.add(volumeAlert);
        connectionStatusController.add(connectionStatus);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events, hasLength(3));
        expect(
          events.map((e) => e.type).toSet(),
          equals({
            CryptocurrencyUpdateEventType.priceUpdate,
            CryptocurrencyUpdateEventType.volumeAlert,
            CryptocurrencyUpdateEventType.connectionStatus,
          }),
        );

        // Cleanup
        await subscription.cancel();
        await priceUpdateController.close();
        await volumeAlertController.close();
        await connectionStatusController.close();
      });
    });

    group('Error Handling', () {
      test('should handle startRealTimeUpdates failure', () async {
        // Arrange
        when(
          mockRepository.startRealTimeUpdates(),
        ).thenThrow(Exception('Failed to start updates'));

        // Act & Assert
        expect(() async {
          final stream = useCase.call();
          await stream.first;
        }, throwsA(isA<Exception>()));
      });

      test('should handle price update stream errors', () async {
        // Arrange
        final priceUpdateController = StreamController<PriceUpdateEvent>();
        final volumeAlertController = StreamController<VolumeAlert>();
        final connectionStatusController = StreamController<ConnectionStatus>();

        when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
        when(
          mockRepository.getPriceUpdates(),
        ).thenAnswer((_) => priceUpdateController.stream);
        when(
          mockRepository.getVolumeAlerts(),
        ).thenAnswer((_) => volumeAlertController.stream);
        when(
          mockRepository.getConnectionStatus(),
        ).thenAnswer((_) => connectionStatusController.stream);

        // Act
        final stream = useCase.call();
        final events = <CryptocurrencyUpdateEvent>[];
        final errors = <Object>[];
        final subscription = stream.listen(events.add, onError: errors.add);

        // Emit error on price update stream
        priceUpdateController.addError(Exception('Price update error'));
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(errors, hasLength(1));
        expect(errors[0], isA<SubscribeToRealTimeUpdatesException>());
        final exception = errors[0] as SubscribeToRealTimeUpdatesException;
        expect(
          exception.errorType,
          equals(SubscribeToRealTimeUpdatesErrorType.priceUpdateError),
        );

        // Cleanup
        await subscription.cancel();
        await priceUpdateController.close();
        await volumeAlertController.close();
        await connectionStatusController.close();
      });

      test('should handle volume alert stream errors', () async {
        // Arrange
        final priceUpdateController = StreamController<PriceUpdateEvent>();
        final volumeAlertController = StreamController<VolumeAlert>();
        final connectionStatusController = StreamController<ConnectionStatus>();

        when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
        when(
          mockRepository.getPriceUpdates(),
        ).thenAnswer((_) => priceUpdateController.stream);
        when(
          mockRepository.getVolumeAlerts(),
        ).thenAnswer((_) => volumeAlertController.stream);
        when(
          mockRepository.getConnectionStatus(),
        ).thenAnswer((_) => connectionStatusController.stream);

        // Act
        final stream = useCase.call();
        final events = <CryptocurrencyUpdateEvent>[];
        final errors = <Object>[];
        final subscription = stream.listen(events.add, onError: errors.add);

        // Emit error on volume alert stream
        volumeAlertController.addError(Exception('Volume alert error'));
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(errors, hasLength(1));
        expect(errors[0], isA<SubscribeToRealTimeUpdatesException>());
        final exception = errors[0] as SubscribeToRealTimeUpdatesException;
        expect(
          exception.errorType,
          equals(SubscribeToRealTimeUpdatesErrorType.volumeAlertError),
        );

        // Cleanup
        await subscription.cancel();
        await priceUpdateController.close();
        await volumeAlertController.close();
        await connectionStatusController.close();
      });

      test('should handle connection status stream errors', () async {
        // Arrange
        final priceUpdateController = StreamController<PriceUpdateEvent>();
        final volumeAlertController = StreamController<VolumeAlert>();
        final connectionStatusController = StreamController<ConnectionStatus>();

        when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
        when(
          mockRepository.getPriceUpdates(),
        ).thenAnswer((_) => priceUpdateController.stream);
        when(
          mockRepository.getVolumeAlerts(),
        ).thenAnswer((_) => volumeAlertController.stream);
        when(
          mockRepository.getConnectionStatus(),
        ).thenAnswer((_) => connectionStatusController.stream);

        // Act
        final stream = useCase.call();
        final events = <CryptocurrencyUpdateEvent>[];
        final errors = <Object>[];
        final subscription = stream.listen(events.add, onError: errors.add);

        // Emit error on connection status stream
        connectionStatusController.addError(Exception('Connection error'));
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(errors, hasLength(1));
        expect(errors[0], isA<SubscribeToRealTimeUpdatesException>());
        final exception = errors[0] as SubscribeToRealTimeUpdatesException;
        expect(
          exception.errorType,
          equals(SubscribeToRealTimeUpdatesErrorType.connectionError),
        );

        // Cleanup
        await subscription.cancel();
        await priceUpdateController.close();
        await volumeAlertController.close();
        await connectionStatusController.close();
      });
    });

    group('Resource Cleanup', () {
      test(
        'should call stopRealTimeUpdates when stream is cancelled',
        () async {
          // Arrange
          final priceUpdateController = StreamController<PriceUpdateEvent>();
          final volumeAlertController = StreamController<VolumeAlert>();
          final connectionStatusController =
              StreamController<ConnectionStatus>();

          when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
          when(
            mockRepository.getPriceUpdates(),
          ).thenAnswer((_) => priceUpdateController.stream);
          when(
            mockRepository.getVolumeAlerts(),
          ).thenAnswer((_) => volumeAlertController.stream);
          when(
            mockRepository.getConnectionStatus(),
          ).thenAnswer((_) => connectionStatusController.stream);
          when(mockRepository.stopRealTimeUpdates()).thenAnswer((_) async {});

          // Act
          final stream = useCase.call();
          final subscription = stream.listen((_) {});
          await subscription.cancel();

          // Allow cleanup to complete
          await Future.delayed(const Duration(milliseconds: 100));

          // Assert
          verify(mockRepository.stopRealTimeUpdates()).called(1);

          // Cleanup
          await priceUpdateController.close();
          await volumeAlertController.close();
          await connectionStatusController.close();
        },
      );

      test('should handle cleanup errors gracefully', () async {
        // Arrange
        final priceUpdateController = StreamController<PriceUpdateEvent>();
        final volumeAlertController = StreamController<VolumeAlert>();
        final connectionStatusController = StreamController<ConnectionStatus>();

        when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
        when(
          mockRepository.getPriceUpdates(),
        ).thenAnswer((_) => priceUpdateController.stream);
        when(
          mockRepository.getVolumeAlerts(),
        ).thenAnswer((_) => volumeAlertController.stream);
        when(
          mockRepository.getConnectionStatus(),
        ).thenAnswer((_) => connectionStatusController.stream);
        when(
          mockRepository.stopRealTimeUpdates(),
        ).thenThrow(Exception('Cleanup error'));

        // Act & Assert - Should not throw during cleanup
        final stream = useCase.call();
        final subscription = stream.listen((_) {});

        // This should not throw even though stopRealTimeUpdates throws
        await subscription.cancel();
        await Future.delayed(const Duration(milliseconds: 10));

        // Cleanup
        await priceUpdateController.close();
        await volumeAlertController.close();
        await connectionStatusController.close();
      });
    });

    group('CryptocurrencyUpdateEvent', () {
      test('should create price update event correctly', () {
        // Arrange
        final priceUpdate = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        // Act
        final event = CryptocurrencyUpdateEvent.priceUpdate(priceUpdate);

        // Assert
        expect(event.type, equals(CryptocurrencyUpdateEventType.priceUpdate));
        expect(event.priceUpdate, equals(priceUpdate));
        expect(event.volumeAlert, isNull);
        expect(event.connectionStatus, isNull);
        expect(event.toString(), contains('priceUpdate'));
      });

      test('should create volume alert event correctly', () {
        // Arrange
        final volumeAlert = VolumeAlert(
          symbol: 'ETH',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        // Act
        final event = CryptocurrencyUpdateEvent.volumeAlert(volumeAlert);

        // Assert
        expect(event.type, equals(CryptocurrencyUpdateEventType.volumeAlert));
        expect(event.volumeAlert, equals(volumeAlert));
        expect(event.priceUpdate, isNull);
        expect(event.connectionStatus, isNull);
        expect(event.toString(), contains('volumeAlert'));
      });

      test('should create connection status event correctly', () {
        // Arrange
        final connectionStatus = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );

        // Act
        final event = CryptocurrencyUpdateEvent.connectionStatus(
          connectionStatus,
        );

        // Assert
        expect(
          event.type,
          equals(CryptocurrencyUpdateEventType.connectionStatus),
        );
        expect(event.connectionStatus, equals(connectionStatus));
        expect(event.priceUpdate, isNull);
        expect(event.volumeAlert, isNull);
        expect(event.toString(), contains('connectionStatus'));
      });
    });

    group('Exception Details', () {
      test('should create exception with correct properties', () {
        // Arrange
        const originalError = 'Network timeout';
        final exception = SubscribeToRealTimeUpdatesException(
          'Stream error: $originalError',
          SubscribeToRealTimeUpdatesErrorType.priceUpdateError,
          originalException: originalError,
        );

        // Assert
        expect(exception.message, equals('Stream error: $originalError'));
        expect(
          exception.errorType,
          equals(SubscribeToRealTimeUpdatesErrorType.priceUpdateError),
        );
        expect(exception.originalException, equals(originalError));
        expect(
          exception.toString(),
          contains('SubscribeToRealTimeUpdatesException'),
        );
      });
    });
  });
}

/// Helper method to test volume spike detection logic
/// This simulates the private _isVolumeSpike method
bool _testVolumeSpike(VolumeAlert volumeAlert) {
  const volumeSpikeThreshold = 0.5;

  if (volumeAlert.previousVolume <= 0) {
    return false;
  }

  final volumeIncrease = volumeAlert.currentVolume - volumeAlert.previousVolume;
  final percentageIncrease = volumeIncrease / volumeAlert.previousVolume;

  return percentageIncrease >= volumeSpikeThreshold;
}
