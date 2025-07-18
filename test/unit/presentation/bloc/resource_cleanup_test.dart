import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../../lib/presentation/bloc/cryptocurrency_bloc.dart';
import '../../../../lib/presentation/bloc/cryptocurrency_event.dart';
import '../../../../lib/domain/usecases/get_initial_cryptocurrencies.dart';
import '../../../../lib/domain/usecases/subscribe_to_real_time_updates.dart';
import '../../../../lib/domain/usecases/manage_connection_lifecycle.dart';
import '../../../../lib/domain/entities/entities.dart';
import 'resource_cleanup_test.mocks.dart';

@GenerateMocks([
  GetInitialCryptocurrencies,
  SubscribeToRealTimeUpdates,
  ManageConnectionLifecycle,
])
void main() {
  group('Resource Cleanup Tests', () {
    late CryptocurrencyBloc bloc;
    late MockGetInitialCryptocurrencies mockGetInitialCryptocurrencies;
    late MockSubscribeToRealTimeUpdates mockSubscribeToRealTimeUpdates;
    late MockManageConnectionLifecycle mockManageConnectionLifecycle;

    setUp(() {
      mockGetInitialCryptocurrencies = MockGetInitialCryptocurrencies();
      mockSubscribeToRealTimeUpdates = MockSubscribeToRealTimeUpdates();
      mockManageConnectionLifecycle = MockManageConnectionLifecycle();

      bloc = CryptocurrencyBloc(
        getInitialCryptocurrencies: mockGetInitialCryptocurrencies,
        subscribeToRealTimeUpdates: mockSubscribeToRealTimeUpdates,
        manageConnectionLifecycle: mockManageConnectionLifecycle,
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    group('BLoC Resource Cleanup', () {
      test('should properly dispose resources when close is called', () async {
        // Arrange
        when(mockManageConnectionLifecycle.isUpdating).thenReturn(true);
        when(
          mockManageConnectionLifecycle.stopUpdates(),
        ).thenAnswer((_) async {});
        when(
          mockManageConnectionLifecycle.gracefulShutdown(),
        ).thenAnswer((_) async {});

        // Act
        await bloc.close();

        // Assert
        verify(mockManageConnectionLifecycle.stopUpdates()).called(1);
        verify(mockManageConnectionLifecycle.gracefulShutdown()).called(1);
      });

      test('should handle errors during cleanup gracefully', () async {
        // Arrange
        when(mockManageConnectionLifecycle.isUpdating).thenReturn(true);
        when(
          mockManageConnectionLifecycle.stopUpdates(),
        ).thenThrow(Exception('Stop failed'));
        when(
          mockManageConnectionLifecycle.gracefulShutdown(),
        ).thenAnswer((_) async {});

        // Act & Assert - should not throw
        await expectLater(bloc.close(), completes);

        verify(mockManageConnectionLifecycle.stopUpdates()).called(1);
        verify(mockManageConnectionLifecycle.gracefulShutdown()).called(1);
      });

      test('should not call stopUpdates if not updating', () async {
        // Arrange
        when(mockManageConnectionLifecycle.isUpdating).thenReturn(false);
        when(
          mockManageConnectionLifecycle.gracefulShutdown(),
        ).thenAnswer((_) async {});

        // Act
        await bloc.close();

        // Assert
        verifyNever(mockManageConnectionLifecycle.stopUpdates());
        verify(mockManageConnectionLifecycle.gracefulShutdown()).called(1);
      });
    });

    group('Stream Subscription Cleanup', () {
      test('should cancel stream subscriptions on close', () async {
        // Arrange
        final streamController = StreamController<CryptocurrencyUpdateEvent>();
        when(
          mockSubscribeToRealTimeUpdates.call(),
        ).thenAnswer((_) => streamController.stream);
        when(mockManageConnectionLifecycle.getStatus()).thenAnswer(
          (_) => Stream.value(
            ConnectionStatus(
              isConnected: true,
              statusMessage: 'Connected',
              lastUpdate: DateTime.now(),
            ),
          ),
        );
        when(mockManageConnectionLifecycle.isUpdating).thenReturn(false);
        when(
          mockManageConnectionLifecycle.gracefulShutdown(),
        ).thenAnswer((_) async {});

        // Start real-time updates to create subscriptions
        bloc.add(const StartRealTimeUpdates());
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        await bloc.close();

        // Assert
        expect(streamController.hasListener, isFalse);
        await streamController.close();
      });
    });

    group('App Lifecycle Resource Management', () {
      test('should stop updates when app goes to background', () async {
        // Arrange
        when(
          mockManageConnectionLifecycle.stopUpdates(),
        ).thenAnswer((_) async {});

        // Act
        bloc.add(const AppLifecycleChanged(false));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockManageConnectionLifecycle.stopUpdates()).called(1);
      });

      test('should start updates when app comes to foreground', () async {
        // Arrange
        final cryptocurrencies = [
          Cryptocurrency(
            symbol: 'BTC',
            name: 'Bitcoin',
            price: 50000.0,
            priceChange24h: 1000.0,
            volume24h: 1000000.0,
            status: ListingStatus.active,
            lastUpdated: DateTime.now(),
            hasVolumeSpike: false,
          ),
        ];

        when(
          mockGetInitialCryptocurrencies.call(),
        ).thenAnswer((_) async => cryptocurrencies);
        when(
          mockManageConnectionLifecycle.startUpdates(),
        ).thenAnswer((_) async {});

        // Load initial data first
        bloc.add(const LoadInitialData());
        await Future.delayed(const Duration(milliseconds: 100));

        // Act
        bloc.add(const AppLifecycleChanged(true));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(
          mockManageConnectionLifecycle.startUpdates(),
        ).called(greaterThan(0));
      });
    });
  });
}
