import 'dart:async';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:crypto_dashboard/presentation/bloc/bloc.dart';
import 'package:crypto_dashboard/domain/usecases/get_initial_cryptocurrencies.dart';
import 'package:crypto_dashboard/domain/usecases/subscribe_to_real_time_updates.dart';
import 'package:crypto_dashboard/domain/usecases/manage_connection_lifecycle.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';

import 'cryptocurrency_bloc_simple_test.mocks.dart';

@GenerateMocks([
  GetInitialCryptocurrencies,
  SubscribeToRealTimeUpdates,
  ManageConnectionLifecycle,
])
void main() {
  group('CryptocurrencyBloc Simple Tests', () {
    late CryptocurrencyBloc bloc;
    late MockGetInitialCryptocurrencies mockGetInitialCryptocurrencies;
    late MockSubscribeToRealTimeUpdates mockSubscribeToRealTimeUpdates;
    late MockManageConnectionLifecycle mockManageConnectionLifecycle;

    // Test data
    late List<Cryptocurrency> testCryptocurrencies;
    late ConnectionStatus testConnectionStatus;
    late PriceUpdateEvent testPriceUpdate;
    late VolumeAlert testVolumeAlert;

    setUp(() {
      mockGetInitialCryptocurrencies = MockGetInitialCryptocurrencies();
      mockSubscribeToRealTimeUpdates = MockSubscribeToRealTimeUpdates();
      mockManageConnectionLifecycle = MockManageConnectionLifecycle();

      // Setup test data
      testCryptocurrencies = [
        Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 1000.0,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
          hasVolumeSpike: false,
        ),
        Cryptocurrency(
          symbol: 'ETH',
          name: 'Ethereum',
          price: 3000.0,
          priceChange24h: -100.0,
          volume24h: 500000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
          hasVolumeSpike: false,
        ),
      ];

      testConnectionStatus = ConnectionStatus(
        isConnected: true,
        statusMessage: 'Connected',
        lastUpdate: DateTime(2024, 1, 1, 12, 0, 0),
      );

      testPriceUpdate = PriceUpdateEvent(
        symbol: 'BTC',
        newPrice: 51000.0,
        priceChange: 1000.0,
        timestamp: DateTime(2024, 1, 1, 12, 1, 0),
      );

      testVolumeAlert = VolumeAlert(
        symbol: 'BTC',
        currentVolume: 1500000.0,
        previousVolume: 1000000.0,
        spikePercentage: 0.5,
      );

      bloc = CryptocurrencyBloc(
        getInitialCryptocurrencies: mockGetInitialCryptocurrencies,
        subscribeToRealTimeUpdates: mockSubscribeToRealTimeUpdates,
        manageConnectionLifecycle: mockManageConnectionLifecycle,
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    group('Initial State', () {
      test('should have CryptocurrencyInitial as initial state', () {
        expect(bloc.state, isA<CryptocurrencyInitial>());
      });
    });

    group('LoadInitialData Event', () {
      test('should emit loading state when LoadInitialData is added', () async {
        // Arrange
        when(
          mockGetInitialCryptocurrencies.call(),
        ).thenAnswer((_) async => testCryptocurrencies);
        when(
          mockManageConnectionLifecycle.startUpdates(),
        ).thenAnswer((_) async {});
        when(
          mockSubscribeToRealTimeUpdates.call(),
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockManageConnectionLifecycle.getStatus(),
        ).thenAnswer((_) => Stream.value(testConnectionStatus));

        // Act
        final states = <CryptocurrencyState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const LoadInitialData());

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(states.length, greaterThan(0));
        expect(states.first, isA<CryptocurrencyLoading>());

        if (states.length > 1) {
          expect(states.last, isA<CryptocurrencyLoaded>());
          final loadedState = states.last as CryptocurrencyLoaded;
          expect(loadedState.cryptocurrencies.length, equals(2));
          expect(loadedState.cryptocurrencies.first.symbol, equals('BTC'));
        }

        await subscription.cancel();
        verify(mockGetInitialCryptocurrencies.call()).called(1);
      });

      test('should emit error state when LoadInitialData fails', () async {
        // Arrange
        when(
          mockGetInitialCryptocurrencies.call(),
        ).thenThrow(Exception('API Error'));

        // Act
        final states = <CryptocurrencyState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const LoadInitialData());

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(states.length, greaterThan(1));
        expect(states.first, isA<CryptocurrencyLoading>());
        expect(states.last, isA<CryptocurrencyError>());

        final errorState = states.last as CryptocurrencyError;
        expect(errorState.message, equals('Failed to load cryptocurrencies'));
        expect(errorState.details, contains('API Error'));

        await subscription.cancel();
      });

      test('should emit error when no cryptocurrencies found', () async {
        // Arrange
        when(
          mockGetInitialCryptocurrencies.call(),
        ).thenAnswer((_) async => <Cryptocurrency>[]);

        // Act
        final states = <CryptocurrencyState>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(const LoadInitialData());

        // Wait for async operations
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(states.length, greaterThan(1));
        expect(states.first, isA<CryptocurrencyLoading>());
        expect(states.last, isA<CryptocurrencyError>());

        final errorState = states.last as CryptocurrencyError;
        expect(errorState.message, equals('No cryptocurrencies found'));

        await subscription.cancel();
      });
    });

    group('State Management', () {
      test('should handle price updates correctly', () async {
        // Arrange - Set up initial loaded state
        when(
          mockGetInitialCryptocurrencies.call(),
        ).thenAnswer((_) async => testCryptocurrencies);
        when(
          mockManageConnectionLifecycle.startUpdates(),
        ).thenAnswer((_) async {});
        when(
          mockSubscribeToRealTimeUpdates.call(),
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockManageConnectionLifecycle.getStatus(),
        ).thenAnswer((_) => Stream.value(testConnectionStatus));

        final states = <CryptocurrencyState>[];
        final subscription = bloc.stream.listen(states.add);

        // Load initial data first
        bloc.add(const LoadInitialData());
        await Future.delayed(const Duration(milliseconds: 100));

        // Act - Add price update
        bloc.add(PriceUpdated(testPriceUpdate));
        await Future.delayed(
          const Duration(milliseconds: 400),
        ); // Wait for debouncing

        // Assert
        final loadedStates = states.whereType<CryptocurrencyLoaded>().toList();
        expect(loadedStates.length, greaterThan(1));

        final finalState = loadedStates.last;
        expect(finalState.cryptocurrencies.first.price, equals(51000.0));
        expect(finalState.cryptocurrencies.first.symbol, equals('BTC'));

        await subscription.cancel();
      });

      test('should handle volume alerts correctly', () async {
        // Arrange - Set up initial loaded state
        when(
          mockGetInitialCryptocurrencies.call(),
        ).thenAnswer((_) async => testCryptocurrencies);
        when(
          mockManageConnectionLifecycle.startUpdates(),
        ).thenAnswer((_) async {});
        when(
          mockSubscribeToRealTimeUpdates.call(),
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockManageConnectionLifecycle.getStatus(),
        ).thenAnswer((_) => Stream.value(testConnectionStatus));

        final states = <CryptocurrencyState>[];
        final subscription = bloc.stream.listen(states.add);

        // Load initial data first
        bloc.add(const LoadInitialData());
        await Future.delayed(const Duration(milliseconds: 100));

        // Act - Add volume alert
        bloc.add(VolumeAlertReceived(testVolumeAlert));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final loadedStates = states.whereType<CryptocurrencyLoaded>().toList();
        expect(loadedStates.length, greaterThan(1));

        final finalState = loadedStates.last;
        expect(finalState.activeAlerts.length, equals(1));
        expect(finalState.activeAlerts['BTC'], equals(testVolumeAlert));

        await subscription.cancel();
      });

      test('should handle connection status changes', () async {
        // Arrange - Set up initial loaded state
        when(
          mockGetInitialCryptocurrencies.call(),
        ).thenAnswer((_) async => testCryptocurrencies);
        when(
          mockManageConnectionLifecycle.startUpdates(),
        ).thenAnswer((_) async {});
        when(
          mockSubscribeToRealTimeUpdates.call(),
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockManageConnectionLifecycle.getStatus(),
        ).thenAnswer((_) => Stream.value(testConnectionStatus));

        final states = <CryptocurrencyState>[];
        final subscription = bloc.stream.listen(states.add);

        // Load initial data first
        bloc.add(const LoadInitialData());
        await Future.delayed(const Duration(milliseconds: 100));

        // Act - Change connection status
        final newStatus = testConnectionStatus.copyWith(
          isConnected: false,
          statusMessage: 'Disconnected',
        );
        bloc.add(ConnectionStatusChanged(newStatus));
        await Future.delayed(
          const Duration(milliseconds: 700),
        ); // Wait for throttling

        // Assert
        final loadedStates = states.whereType<CryptocurrencyLoaded>().toList();
        expect(loadedStates.length, greaterThan(1));

        final finalState = loadedStates.last;
        expect(finalState.connectionStatus.isConnected, equals(false));
        expect(
          finalState.connectionStatus.statusMessage,
          equals('Disconnected'),
        );

        await subscription.cancel();
      });
    });

    group('Real-time Updates', () {
      test('should handle start and stop real-time updates', () async {
        // Arrange
        when(
          mockManageConnectionLifecycle.startUpdates(),
        ).thenAnswer((_) async {});
        when(
          mockManageConnectionLifecycle.stopUpdates(),
        ).thenAnswer((_) async {});
        when(
          mockSubscribeToRealTimeUpdates.call(),
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockManageConnectionLifecycle.getStatus(),
        ).thenAnswer((_) => Stream.value(testConnectionStatus));

        // Create initial loaded state
        final initialState = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime.now(),
        );

        final states = <CryptocurrencyState>[];
        final subscription = bloc.stream.listen(states.add);

        // Manually emit the loaded state (simulating loaded state)
        bloc.emit(initialState);

        // Act - Start updates
        bloc.add(const StartRealTimeUpdates());
        await Future.delayed(const Duration(milliseconds: 100));

        // Act - Stop updates
        bloc.add(const StopRealTimeUpdates());
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockManageConnectionLifecycle.startUpdates()).called(1);
        verify(mockManageConnectionLifecycle.stopUpdates()).called(1);

        await subscription.cancel();
      });
    });

    group('Error Handling', () {
      test('should handle start updates failure gracefully', () async {
        // Arrange
        when(
          mockManageConnectionLifecycle.startUpdates(),
        ).thenThrow(Exception('Connection failed'));

        // Create initial loaded state
        final initialState = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime.now(),
        );

        final states = <CryptocurrencyState>[];
        final subscription = bloc.stream.listen(states.add);

        // Manually emit the loaded state
        bloc.emit(initialState);

        // Act
        bloc.add(const StartRealTimeUpdates());
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final loadedStates = states.whereType<CryptocurrencyLoaded>().toList();
        expect(loadedStates.length, greaterThan(0));

        final finalState = loadedStates.last;
        expect(finalState.connectionStatus.isConnected, equals(false));
        expect(
          finalState.connectionStatus.statusMessage,
          contains('Failed to start updates'),
        );

        await subscription.cancel();
      });

      test('should handle stop updates failure gracefully', () async {
        // Arrange
        when(
          mockManageConnectionLifecycle.stopUpdates(),
        ).thenThrow(Exception('Stop failed'));

        // Create initial loaded state
        final initialState = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime.now(),
        );

        final states = <CryptocurrencyState>[];
        final subscription = bloc.stream.listen(states.add);

        // Manually emit the loaded state
        bloc.emit(initialState);

        // Act
        bloc.add(const StopRealTimeUpdates());
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final loadedStates = states.whereType<CryptocurrencyLoaded>().toList();
        expect(loadedStates.length, greaterThan(0));

        final finalState = loadedStates.last;
        expect(finalState.connectionStatus.isConnected, equals(false));
        expect(
          finalState.connectionStatus.statusMessage,
          contains('Stopped with error'),
        );

        await subscription.cancel();
      });
    });

    group('App Lifecycle', () {
      test('should handle app lifecycle changes', () async {
        // Arrange
        when(
          mockManageConnectionLifecycle.startUpdates(),
        ).thenAnswer((_) async {});
        when(
          mockManageConnectionLifecycle.stopUpdates(),
        ).thenAnswer((_) async {});
        when(
          mockSubscribeToRealTimeUpdates.call(),
        ).thenAnswer((_) => const Stream.empty());
        when(
          mockManageConnectionLifecycle.getStatus(),
        ).thenAnswer((_) => Stream.value(testConnectionStatus));

        // Create initial loaded state
        final initialState = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime.now(),
        );

        final subscription = bloc.stream.listen((_) {});

        // Manually emit the loaded state
        bloc.emit(initialState);

        // Act - App goes to background
        bloc.add(const AppLifecycleChanged(false));
        await Future.delayed(const Duration(milliseconds: 100));

        // Act - App comes to foreground
        bloc.add(const AppLifecycleChanged(true));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockManageConnectionLifecycle.stopUpdates()).called(1);
        verify(mockManageConnectionLifecycle.startUpdates()).called(1);

        await subscription.cancel();
      });
    });
  });
}
