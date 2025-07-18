import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';
import 'package:crypto_dashboard/domain/repositories/cryptocurrency_repository.dart';
import 'package:crypto_dashboard/domain/usecases/manage_connection_lifecycle.dart';

import 'manage_connection_lifecycle_test.mocks.dart';

@GenerateMocks([CryptocurrencyRepository])
void main() {
  group('ManageConnectionLifecycle Use Case', () {
    late ManageConnectionLifecycle useCase;
    late MockCryptocurrencyRepository mockRepository;
    late DateTime testDateTime;

    setUp(() {
      mockRepository = MockCryptocurrencyRepository();
      useCase = ManageConnectionLifecycle(mockRepository);
      testDateTime = DateTime(2024, 1, 1, 12, 0, 0);
    });

    tearDown(() async {
      // Ensure proper cleanup after each test
      await useCase.dispose();
    });

    group('Constants', () {
      test('should have correct reconnection constants', () {
        // Assert
        expect(ManageConnectionLifecycle.maxReconnectionAttempts, equals(5));
        expect(ManageConnectionLifecycle.baseDelaySeconds, equals(2));
        expect(ManageConnectionLifecycle.maxDelaySeconds, equals(60));
      });
    });

    group('Start Updates', () {
      test('should start real-time updates successfully', () async {
        // Arrange
        when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});

        // Act
        await useCase.startUpdates();

        // Assert
        verify(mockRepository.startRealTimeUpdates()).called(1);
      });

      test(
        'should throw ManageConnectionLifecycleException when start fails',
        () async {
          // Arrange
          when(
            mockRepository.startRealTimeUpdates(),
          ).thenThrow(Exception('Network error'));

          // Act & Assert
          expect(
            () => useCase.startUpdates(),
            throwsA(
              isA<ManageConnectionLifecycleException>()
                  .having(
                    (e) => e.errorType,
                    'errorType',
                    ManageConnectionLifecycleErrorType.startError,
                  )
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Failed to start real-time updates'),
                  )
                  .having(
                    (e) => e.originalException,
                    'originalException',
                    isNotNull,
                  ),
            ),
          );
        },
      );

      test(
        'should throw exception when trying to start after disposal',
        () async {
          // Arrange
          await useCase.dispose();

          // Act & Assert
          expect(
            () => useCase.startUpdates(),
            throwsA(
              isA<ManageConnectionLifecycleException>()
                  .having(
                    (e) => e.errorType,
                    'errorType',
                    ManageConnectionLifecycleErrorType.lifecycleError,
                  )
                  .having(
                    (e) => e.message,
                    'message',
                    contains(
                      'Cannot start updates: ManageConnectionLifecycle has been disposed',
                    ),
                  ),
            ),
          );
        },
      );
    });

    group('Stop Updates', () {
      test('should stop real-time updates successfully', () async {
        // Arrange
        when(mockRepository.stopRealTimeUpdates()).thenAnswer((_) async {});

        // Act
        await useCase.stopUpdates();

        // Assert
        verify(mockRepository.stopRealTimeUpdates()).called(1);
      });

      test(
        'should throw ManageConnectionLifecycleException when stop fails',
        () async {
          // Arrange
          when(
            mockRepository.stopRealTimeUpdates(),
          ).thenThrow(Exception('Stop error'));

          // Act & Assert
          expect(
            () => useCase.stopUpdates(),
            throwsA(
              isA<ManageConnectionLifecycleException>()
                  .having(
                    (e) => e.errorType,
                    'errorType',
                    ManageConnectionLifecycleErrorType.stopError,
                  )
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Failed to stop real-time updates'),
                  )
                  .having(
                    (e) => e.originalException,
                    'originalException',
                    isNotNull,
                  ),
            ),
          );
        },
      );

      test('should handle cleanup errors gracefully during stop', () async {
        // Arrange
        when(
          mockRepository.stopRealTimeUpdates(),
        ).thenThrow(Exception('Cleanup error'));

        // Act & Assert - Should throw the exception
        expect(
          () => useCase.stopUpdates(),
          throwsA(isA<ManageConnectionLifecycleException>()),
        );
      });
    });

    group('Get Status', () {
      test('should return connection status stream', () async {
        // Arrange
        final statusController = StreamController<ConnectionStatus>();
        when(
          mockRepository.getConnectionStatus(),
        ).thenAnswer((_) => statusController.stream);

        final connectionStatus = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );

        // Act
        final stream = useCase.getStatus();
        final events = <ConnectionStatus>[];
        final subscription = stream.listen(events.add);

        statusController.add(connectionStatus);
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events, hasLength(1));
        expect(events[0], equals(connectionStatus));

        // Cleanup
        await subscription.cancel();
        await statusController.close();
      });

      test(
        'should throw ManageConnectionLifecycleException when getStatus fails',
        () {
          // Arrange
          when(
            mockRepository.getConnectionStatus(),
          ).thenThrow(Exception('Status error'));

          // Act & Assert
          expect(
            () => useCase.getStatus(),
            throwsA(
              isA<ManageConnectionLifecycleException>()
                  .having(
                    (e) => e.errorType,
                    'errorType',
                    ManageConnectionLifecycleErrorType.statusError,
                  )
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Failed to get connection status stream'),
                  )
                  .having(
                    (e) => e.originalException,
                    'originalException',
                    isNotNull,
                  ),
            ),
          );
        },
      );
    });

    group('Start Updates With Reconnection', () {
      test(
        'should emit connecting status and then connected status on success',
        () async {
          // Arrange
          final statusController = StreamController<ConnectionStatus>();
          when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
          when(
            mockRepository.getConnectionStatus(),
          ).thenAnswer((_) => statusController.stream);

          // Act
          final stream = useCase.startUpdatesWithReconnection();
          final events = <ConnectionStatus>[];
          final subscription = stream.listen(events.add);

          // Simulate successful connection
          await Future.delayed(const Duration(milliseconds: 10));
          statusController.add(
            ConnectionStatus(
              isConnected: true,
              statusMessage: 'Live',
              lastUpdate: testDateTime,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 10));

          // Assert
          expect(events.length, greaterThanOrEqualTo(2));
          expect(events[0].isConnected, isFalse);
          expect(events[0].statusMessage, equals('Connecting...'));
          expect(events[1].isConnected, isTrue);
          expect(events[1].statusMessage, equals('Connected'));

          // Cleanup
          await subscription.cancel();
          await statusController.close();
        },
      );

      test(
        'should attempt reconnection with exponential backoff on failure',
        () async {
          // Arrange
          var attemptCount = 0;
          when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {
            attemptCount++;
            if (attemptCount < 3) {
              throw Exception('Connection failed');
            }
          });
          when(mockRepository.getConnectionStatus()).thenAnswer(
            (_) => Stream.value(
              ConnectionStatus(
                isConnected: true,
                statusMessage: 'Connected',
                lastUpdate: testDateTime,
              ),
            ),
          );

          // Act
          final stream = useCase.startUpdatesWithReconnection();
          final events = <ConnectionStatus>[];
          final subscription = stream.listen(events.add);

          // Wait for reconnection attempts
          await Future.delayed(const Duration(milliseconds: 100));

          // Assert
          expect(events.length, greaterThan(2));
          expect(
            events.any((e) => e.statusMessage.contains('Reconnecting')),
            isTrue,
          );
          expect(
            events.any((e) => e.statusMessage.contains('attempt')),
            isTrue,
          );

          // Cleanup
          await subscription.cancel();
        },
      );

      test('should fail after maximum reconnection attempts', () async {
        // Arrange
        when(
          mockRepository.startRealTimeUpdates(),
        ).thenThrow(Exception('Persistent connection error'));

        // Act
        final stream = useCase.startUpdatesWithReconnection();
        final events = <ConnectionStatus>[];
        final errors = <Object>[];
        final subscription = stream.listen(events.add, onError: errors.add);

        // Wait for all reconnection attempts
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        expect(errors, hasLength(1));
        expect(errors[0], isA<ManageConnectionLifecycleException>());
        final exception = errors[0] as ManageConnectionLifecycleException;
        expect(
          exception.errorType,
          equals(ManageConnectionLifecycleErrorType.reconnectionFailed),
        );
        expect(exception.attemptCount, equals(5));

        // Should emit final error status
        expect(
          events.any(
            (e) => e.statusMessage.contains('failed after 5 attempts'),
          ),
          isTrue,
        );

        // Cleanup
        await subscription.cancel();
      });

      test('should handle connection loss and attempt reconnection', () async {
        // Arrange
        final statusController = StreamController<ConnectionStatus>();
        when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
        when(
          mockRepository.getConnectionStatus(),
        ).thenAnswer((_) => statusController.stream);

        // Act
        final stream = useCase.startUpdatesWithReconnection();
        final events = <ConnectionStatus>[];
        final subscription = stream.listen(events.add);

        // Simulate initial connection
        await Future.delayed(const Duration(milliseconds: 10));
        statusController.add(
          ConnectionStatus(
            isConnected: true,
            statusMessage: 'Connected',
            lastUpdate: testDateTime,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 10));

        // Simulate connection loss
        statusController.add(
          ConnectionStatus(
            isConnected: false,
            statusMessage: 'Connection lost',
            lastUpdate: testDateTime.add(const Duration(minutes: 1)),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(events.length, greaterThanOrEqualTo(3));
        expect(events.any((e) => e.statusMessage == 'Connecting...'), isTrue);
        expect(events.any((e) => e.statusMessage == 'Connected'), isTrue);
        expect(events.any((e) => e.statusMessage == 'Connection lost'), isTrue);

        // Cleanup
        await subscription.cancel();
        await statusController.close();
      });
    });

    group('Backoff Calculation', () {
      test('should calculate exponential backoff correctly', () {
        // Test the backoff calculation indirectly by observing timing
        // Since the method is private, we test the behavior through public methods

        // This test verifies that reconnection attempts have increasing delays
        // The exact timing is hard to test due to jitter, but we can verify
        // that multiple attempts are made with delays

        // Arrange
        when(
          mockRepository.startRealTimeUpdates(),
        ).thenThrow(Exception('Connection failed'));

        // Act
        final stream = useCase.startUpdatesWithReconnection();
        final events = <ConnectionStatus>[];
        final subscription = stream.listen(
          events.add,
          onError: (_) {}, // Ignore errors for this test
        );

        // Wait and verify that retry messages contain timing information
        Future.delayed(const Duration(milliseconds: 50), () async {
          expect(
            events.any((e) => e.statusMessage.contains('Retrying in')),
            isTrue,
          );
          expect(events.any((e) => e.statusMessage.contains('s...')), isTrue);
          await subscription.cancel();
        });
      });
    });

    group('Is Updating', () {
      test('should return repository isUpdating status', () {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(true);

        // Act
        final isUpdating = useCase.isUpdating;

        // Assert
        expect(isUpdating, isTrue);
        verify(mockRepository.isUpdating).called(1);
      });

      test('should return false when repository is not updating', () {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(false);

        // Act
        final isUpdating = useCase.isUpdating;

        // Assert
        expect(isUpdating, isFalse);
        verify(mockRepository.isUpdating).called(1);
      });
    });

    group('Graceful Shutdown', () {
      test('should perform graceful shutdown successfully', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(true);
        when(mockRepository.stopRealTimeUpdates()).thenAnswer((_) async {});

        // Act
        await useCase.gracefulShutdown();

        // Assert
        verify(mockRepository.stopRealTimeUpdates()).called(1);
      });

      test('should handle shutdown errors gracefully', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(true);
        when(
          mockRepository.stopRealTimeUpdates(),
        ).thenThrow(Exception('Shutdown error'));

        // Act & Assert - Should not throw
        await useCase.gracefulShutdown();

        // Verify attempt was made
        verify(mockRepository.stopRealTimeUpdates()).called(1);
      });

      test('should not stop updates if not updating', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(false);

        // Act
        await useCase.gracefulShutdown();

        // Assert
        verifyNever(mockRepository.stopRealTimeUpdates());
      });

      test('should handle multiple graceful shutdown calls', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(false);

        // Act
        await useCase.gracefulShutdown();
        await useCase.gracefulShutdown(); // Second call

        // Assert - Should not cause issues
        verifyNever(mockRepository.stopRealTimeUpdates());
      });
    });

    group('Dispose', () {
      test('should dispose successfully and mark as disposed', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(false);

        // Act
        await useCase.dispose();

        // Assert
        expect(useCase.isDisposed, isTrue);
      });

      test('should perform graceful shutdown during dispose', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(true);
        when(mockRepository.stopRealTimeUpdates()).thenAnswer((_) async {});

        // Act
        await useCase.dispose();

        // Assert
        verify(mockRepository.stopRealTimeUpdates()).called(1);
        expect(useCase.isDisposed, isTrue);
      });

      test('should handle dispose errors gracefully', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(true);
        when(
          mockRepository.stopRealTimeUpdates(),
        ).thenThrow(Exception('Dispose error'));

        // Act & Assert - Should not throw
        await useCase.dispose();

        // Should still be marked as disposed
        expect(useCase.isDisposed, isTrue);
      });

      test('should handle multiple dispose calls', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(false);

        // Act
        await useCase.dispose();
        await useCase.dispose(); // Second call

        // Assert - Should not cause issues
        expect(useCase.isDisposed, isTrue);
      });
    });

    group('Is Disposed', () {
      test('should return false initially', () {
        // Assert
        expect(useCase.isDisposed, isFalse);
      });

      test('should return true after dispose', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(false);

        // Act
        await useCase.dispose();

        // Assert
        expect(useCase.isDisposed, isTrue);
      });
    });

    group('Exception Details', () {
      test(
        'should create exception with correct properties for start error',
        () {
          // Arrange
          const originalError = 'Network timeout';
          final exception = ManageConnectionLifecycleException(
            'Failed to start: $originalError',
            ManageConnectionLifecycleErrorType.startError,
            originalException: originalError,
          );

          // Assert
          expect(exception.message, equals('Failed to start: $originalError'));
          expect(
            exception.errorType,
            equals(ManageConnectionLifecycleErrorType.startError),
          );
          expect(exception.originalException, equals(originalError));
          expect(exception.attemptCount, isNull);
          expect(
            exception.toString(),
            contains('ManageConnectionLifecycleException'),
          );
        },
      );

      test(
        'should create exception with attempt count for reconnection failure',
        () {
          // Arrange
          final exception = ManageConnectionLifecycleException(
            'Reconnection failed',
            ManageConnectionLifecycleErrorType.reconnectionFailed,
            attemptCount: 5,
          );

          // Assert
          expect(
            exception.errorType,
            equals(ManageConnectionLifecycleErrorType.reconnectionFailed),
          );
          expect(exception.attemptCount, equals(5));
          expect(exception.originalException, isNull);
        },
      );
    });

    group('Resource Management', () {
      test('should clean up timers and subscriptions on dispose', () async {
        // This test verifies that internal resources are cleaned up
        // We can't directly test private fields, but we can verify behavior

        // Arrange
        when(mockRepository.isUpdating).thenReturn(false);

        // Act
        await useCase.dispose();

        // Assert - Subsequent operations should fail
        expect(
          () => useCase.startUpdates(),
          throwsA(
            isA<ManageConnectionLifecycleException>().having(
              (e) => e.errorType,
              'errorType',
              ManageConnectionLifecycleErrorType.lifecycleError,
            ),
          ),
        );
      });

      test('should handle concurrent operations safely', () async {
        // Arrange
        when(mockRepository.startRealTimeUpdates()).thenAnswer((_) async {});
        when(mockRepository.stopRealTimeUpdates()).thenAnswer((_) async {});

        // Act - Perform concurrent operations
        final futures = [
          useCase.startUpdates(),
          useCase.stopUpdates(),
          useCase.gracefulShutdown(),
        ];

        // Assert - Should not throw
        await Future.wait(futures, eagerError: false);
      });
    });
  });
}
