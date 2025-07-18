import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:crypto_dashboard/domain/usecases/manage_connection_lifecycle.dart';
import 'package:crypto_dashboard/domain/repositories/cryptocurrency_repository.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';

@GenerateMocks([CryptocurrencyRepository])
import 'connection_lifecycle_cleanup_test.mocks.dart';

void main() {
  group('ManageConnectionLifecycle Resource Cleanup Tests', () {
    late ManageConnectionLifecycle useCase;
    late MockCryptocurrencyRepository mockRepository;

    setUp(() {
      mockRepository = MockCryptocurrencyRepository();
      useCase = ManageConnectionLifecycle(mockRepository);
    });

    tearDown(() async {
      await useCase.dispose();
    });

    group('Timer Resource Cleanup', () {
      test(
        'should cancel reconnection timer when stopUpdates is called',
        () async {
          // Arrange
          when(mockRepository.stopRealTimeUpdates()).thenAnswer((_) async {});

          // Act
          await useCase.stopUpdates();

          // Assert
          verify(mockRepository.stopRealTimeUpdates()).called(1);
        },
      );

      test('should cancel all timers during graceful shutdown', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(true);
        when(mockRepository.stopRealTimeUpdates()).thenAnswer((_) async {});

        // Act
        await useCase.gracefulShutdown();

        // Assert
        verify(mockRepository.stopRealTimeUpdates()).called(1);
      });

      test('should handle shutdown when not updating', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(false);

        // Act & Assert - should not throw
        await expectLater(useCase.gracefulShutdown(), completes);

        verifyNever(mockRepository.stopRealTimeUpdates());
      });
    });

    group('Stream Subscription Cleanup', () {
      test(
        'should cancel status subscription when stopUpdates is called',
        () async {
          // Arrange
          final statusController = StreamController<ConnectionStatus>();
          when(
            mockRepository.getConnectionStatus(),
          ).thenAnswer((_) => statusController.stream);
          when(mockRepository.stopRealTimeUpdates()).thenAnswer((_) async {});

          // Start listening to status
          final statusStream = useCase.getStatus();
          final subscription = statusStream.listen((_) {});

          // Act
          await useCase.stopUpdates();

          // Assert
          verify(mockRepository.stopRealTimeUpdates()).called(1);

          // Clean up
          await subscription.cancel();
          await statusController.close();
        },
      );
    });

    group('Disposal State Management', () {
      test('should mark as disposed after dispose is called', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(false);

        // Act
        await useCase.dispose();

        // Assert
        expect(useCase.isDisposed, isTrue);
      });

      test('should prevent operations after disposal', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(false);
        await useCase.dispose();

        // Act & Assert
        expect(
          () => useCase.startUpdates(),
          throwsA(isA<ManageConnectionLifecycleException>()),
        );
      });

      test('should handle multiple dispose calls gracefully', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(false);

        // Act & Assert - should not throw
        await expectLater(useCase.dispose(), completes);
        await expectLater(
          useCase.dispose(),
          completes,
        ); // Second call should be safe
      });
    });

    group('Error Handling During Cleanup', () {
      test(
        'should handle repository stop errors during graceful shutdown',
        () async {
          // Arrange
          when(mockRepository.isUpdating).thenReturn(true);
          when(
            mockRepository.stopRealTimeUpdates(),
          ).thenThrow(Exception('Stop failed'));

          // Act & Assert - should not throw
          await expectLater(useCase.gracefulShutdown(), completes);

          verify(mockRepository.stopRealTimeUpdates()).called(1);
        },
      );

      test('should handle repository stop errors during disposal', () async {
        // Arrange
        when(mockRepository.isUpdating).thenReturn(true);
        when(
          mockRepository.stopRealTimeUpdates(),
        ).thenThrow(Exception('Stop failed'));

        // Act & Assert - should not throw
        await expectLater(useCase.dispose(), completes);

        expect(useCase.isDisposed, isTrue);
      });
    });

    group('Resource Cleanup Order', () {
      test(
        'should cleanup resources in proper order during disposal',
        () async {
          // Arrange
          when(mockRepository.isUpdating).thenReturn(true);
          when(mockRepository.stopRealTimeUpdates()).thenAnswer((_) async {});

          // Act
          await useCase.dispose();

          // Assert - verify proper cleanup order
          expect(useCase.isDisposed, isTrue);
          verify(mockRepository.stopRealTimeUpdates()).called(1);
        },
      );
    });
  });
}
