import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:crypto_dashboard/data/repositories/cryptocurrency_repository_impl.dart';
import 'package:crypto_dashboard/data/datasources/okx_api_service.dart';
import 'package:crypto_dashboard/core/network/network_error_handler.dart';
import 'package:crypto_dashboard/core/network/offline_manager.dart';

@GenerateMocks([OKXApiService, NetworkErrorHandler, OfflineManager])
import 'repository_resource_cleanup_test.mocks.dart';

void main() {
  group('Repository Resource Cleanup Tests', () {
    late CryptocurrencyRepositoryImpl repository;
    late MockOKXApiService mockApiService;
    late MockNetworkErrorHandler mockNetworkErrorHandler;
    late MockOfflineManager mockOfflineManager;

    setUp(() {
      mockApiService = MockOKXApiService();
      mockNetworkErrorHandler = MockNetworkErrorHandler();
      mockOfflineManager = MockOfflineManager();

      repository = CryptocurrencyRepositoryImpl(
        mockApiService,
        mockNetworkErrorHandler,
        mockOfflineManager,
      );
    });

    tearDown(() {
      repository.dispose();
    });

    group('Timer Resource Cleanup', () {
      test(
        'should cancel update timer when stopRealTimeUpdates is called',
        () async {
          // Arrange
          when(mockOfflineManager.isOffline).thenReturn(false);

          // Start updates to create timer
          await repository.startRealTimeUpdates();
          expect(repository.isUpdating, isTrue);

          // Act
          await repository.stopRealTimeUpdates();

          // Assert
          expect(repository.isUpdating, isFalse);
        },
      );

      test('should cancel timer when dispose is called', () async {
        // Arrange
        when(mockOfflineManager.isOffline).thenReturn(false);
        when(mockApiService.dispose()).thenReturn(null);

        // Start updates to create timer
        await repository.startRealTimeUpdates();
        expect(repository.isUpdating, isTrue);

        // Act
        repository.dispose();

        // Assert
        expect(repository.isUpdating, isFalse);
        verify(mockApiService.dispose()).called(1);
      });

      test('should handle multiple dispose calls gracefully', () {
        // Arrange
        when(mockApiService.dispose()).thenReturn(null);

        // Act & Assert - should not throw
        expect(() {
          repository.dispose();
          repository.dispose(); // Second call should be safe
        }, returnsNormally);

        verify(mockApiService.dispose()).called(2);
      });
    });

    group('Stream Controller Cleanup', () {
      test('should close all stream controllers on dispose', () async {
        // Arrange
        when(mockApiService.dispose()).thenReturn(null);

        // Get references to streams to test they're closed
        final priceStream = repository.getPriceUpdates();
        final volumeStream = repository.getVolumeAlerts();
        final connectionStream = repository.getConnectionStatus();

        // Listen to streams to activate them
        final priceSubscription = priceStream.listen((_) {});
        final volumeSubscription = volumeStream.listen((_) {});
        final connectionSubscription = connectionStream.listen((_) {});

        // Act
        repository.dispose();

        // Wait a bit for disposal to complete
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - streams should be closed
        await expectLater(priceStream.isEmpty, completion(isTrue));
        await expectLater(volumeStream.isEmpty, completion(isTrue));
        await expectLater(connectionStream.isEmpty, completion(isTrue));

        // Clean up subscriptions
        await priceSubscription.cancel();
        await volumeSubscription.cancel();
        await connectionSubscription.cancel();
      });
    });

    group('Internal State Cleanup', () {
      test('should clear internal state on dispose', () {
        // Arrange
        when(mockApiService.dispose()).thenReturn(null);

        // Act
        repository.dispose();

        // Assert - isUpdating should be false after dispose
        expect(repository.isUpdating, isFalse);
      });
    });

    group('Error Handling During Cleanup', () {
      test('should handle API service disposal errors gracefully', () {
        // Arrange
        when(mockApiService.dispose()).thenThrow(Exception('Disposal failed'));

        // Act & Assert - should not throw
        expect(() => repository.dispose(), returnsNormally);
      });
    });
  });
}
