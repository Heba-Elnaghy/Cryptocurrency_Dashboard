import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/presentation/bloc/bloc.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';
import 'package:crypto_dashboard/core/utils/performance_monitor.dart';
import 'package:crypto_dashboard/core/utils/debouncer.dart';
import 'package:crypto_dashboard/core/utils/immutable_state.dart';

void main() {
  group('Efficient State Updates', () {
    setUp(() {
      // Enable performance monitoring for tests
      PerformanceMonitor.enable();
    });

    tearDown(() {
      PerformanceMonitor.disable();
      PerformanceMonitor.clearMetrics();
    });

    test('should use immutable state objects for better performance', () {
      // Arrange - Use fixed DateTime to ensure consistent hash codes
      final fixedDateTime = DateTime(2024, 1, 1, 12, 0, 0);

      final connectionStatus = ConnectionStatus(
        isConnected: true,
        statusMessage: 'Connected',
        lastUpdate: fixedDateTime,
      );

      final cryptocurrency = Cryptocurrency(
        symbol: 'BTC',
        name: 'Bitcoin',
        price: 50000.0,
        priceChange24h: 1000.0,
        volume24h: 1000000.0,
        status: ListingStatus.active,
        lastUpdated: fixedDateTime,
        hasVolumeSpike: false,
      );

      final state1 = CryptocurrencyLoaded(
        cryptocurrencies: [cryptocurrency],
        connectionStatus: connectionStatus,
        lastUpdated: fixedDateTime,
      );

      // Act - Create a copy with explicitly the same data
      final state2 = state1.copyWith(
        cryptocurrencies: state1.cryptocurrencies,
        connectionStatus: state1.connectionStatus,
        lastUpdated: state1.lastUpdated,
      );

      // Assert - States should be equal but not identical
      expect(state1 == state2, isTrue);
      expect(identical(state1, state2), isFalse);

      // Test that the state uses efficient equality comparison
      expect(state1.isEqualTo(state2), isTrue);
    });

    test('should optimize state updates with selective changes', () {
      // Arrange
      final cryptocurrency = Cryptocurrency(
        symbol: 'BTC',
        name: 'Bitcoin',
        price: 50000.0,
        priceChange24h: 1000.0,
        volume24h: 1000000.0,
        status: ListingStatus.active,
        lastUpdated: DateTime.now(),
        hasVolumeSpike: false,
      );

      final initialState = CryptocurrencyLoaded(
        cryptocurrencies: [cryptocurrency],
        connectionStatus: ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      // Act - Update only the price
      final updatedCrypto = cryptocurrency.copyWith(price: 51000.0);
      final newState = initialState.updateCryptocurrency(updatedCrypto);

      // Assert - Only the cryptocurrency with updated price should change
      expect(newState.cryptocurrencies.length, equals(1));
      expect(newState.cryptocurrencies.first.price, equals(51000.0));
      expect(newState.cryptocurrencies.first.symbol, equals('BTC'));

      // Connection status should remain the same reference
      expect(
        identical(initialState.connectionStatus, newState.connectionStatus),
        isTrue,
      );
    });

    test('should handle volume alerts efficiently', () {
      // Arrange
      final cryptocurrency = Cryptocurrency(
        symbol: 'BTC',
        name: 'Bitcoin',
        price: 50000.0,
        priceChange24h: 1000.0,
        volume24h: 1000000.0,
        status: ListingStatus.active,
        lastUpdated: DateTime.now(),
        hasVolumeSpike: false,
      );

      final initialState = CryptocurrencyLoaded(
        cryptocurrencies: [cryptocurrency],
        connectionStatus: ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      final volumeAlert = VolumeAlert(
        symbol: 'BTC',
        currentVolume: 1500000.0,
        previousVolume: 1000000.0,
        spikePercentage: 0.5,
      );

      // Act - Add volume alert
      final stateWithAlert = initialState.addVolumeAlert(volumeAlert);

      // Assert
      expect(stateWithAlert.activeAlerts.length, equals(1));
      expect(stateWithAlert.activeAlerts['BTC'], equals(volumeAlert));

      // Act - Remove volume alert
      final stateWithoutAlert = stateWithAlert.removeVolumeAlert('BTC');

      // Assert
      expect(stateWithoutAlert.activeAlerts.length, equals(0));
      expect(stateWithoutAlert.activeAlerts.containsKey('BTC'), isFalse);
    });

    test('should use memoization for expensive computations', () {
      // Arrange
      final cryptocurrencies = List.generate(
        10,
        (index) => Cryptocurrency(
          symbol: 'CRYPTO$index',
          name: 'Cryptocurrency $index',
          price: 1000.0 + index,
          priceChange24h: 10.0 + index,
          volume24h: 100000.0 + index,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
          hasVolumeSpike: index % 3 == 0, // Every 3rd crypto has volume spike
        ),
      );

      final state = CryptocurrencyLoaded(
        cryptocurrencies: cryptocurrencies,
        connectionStatus: ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      // Act - Call memoized getter multiple times
      final volumeSpikes1 = state.cryptocurrenciesWithVolumeSpikes;
      final volumeSpikes2 = state.cryptocurrenciesWithVolumeSpikes;
      final volumeSpikes3 = state.cryptocurrenciesWithVolumeSpikes;

      // Assert - Should return the same reference (memoized)
      expect(identical(volumeSpikes1, volumeSpikes2), isTrue);
      expect(identical(volumeSpikes2, volumeSpikes3), isTrue);
      expect(volumeSpikes1.length, equals(4)); // 0, 3, 6, 9 have volume spikes
    });

    test('should use efficient debouncing utilities', () async {
      // Arrange
      var callCount = 0;
      final debouncer = Debouncer(delay: const Duration(milliseconds: 100));

      // Act - Make multiple rapid calls
      for (int i = 0; i < 5; i++) {
        debouncer.call(() => callCount++);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait for debounce to complete
      await Future.delayed(const Duration(milliseconds: 150));

      // Assert - Should only be called once due to debouncing
      expect(callCount, equals(1));

      debouncer.dispose();
    });

    test('should batch operations efficiently', () async {
      // Arrange
      final batchedItems = <String>[];
      final batcher = Batcher<String>(
        delay: const Duration(milliseconds: 50),
        onBatch: (items) => batchedItems.addAll(items),
      );

      // Act - Add multiple items rapidly
      batcher.add('item1');
      batcher.add('item2');
      batcher.add('item3');

      // Wait for batch to process
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert - All items should be batched together
      expect(batchedItems.length, equals(3));
      expect(batchedItems, containsAll(['item1', 'item2', 'item3']));

      batcher.dispose();
    });

    test('should throttle function calls efficiently', () {
      // Arrange
      var callCount = 0;
      final throttler = Throttler(duration: const Duration(milliseconds: 100));

      // Act - Make multiple rapid calls
      for (int i = 0; i < 5; i++) {
        throttler.call(() => callCount++);
      }

      // Assert - Should only be called once due to throttling
      expect(callCount, equals(1));
    });

    test('should use efficient deep equality comparisons', () {
      // Arrange
      final list1 = [1, 2, 3];
      final list2 = [1, 2, 3];
      final list3 = [1, 2, 4];

      final map1 = {'a': 1, 'b': 2};
      final map2 = {'a': 1, 'b': 2};
      final map3 = {'a': 1, 'b': 3};

      // Act & Assert
      expect(DeepEquality.equals(list1, list2), isTrue);
      expect(DeepEquality.equals(list1, list3), isFalse);
      expect(DeepEquality.equals(map1, map2), isTrue);
      expect(DeepEquality.equals(map1, map3), isFalse);
    });

    test('should use state updater for efficient updates', () {
      // Arrange
      final initialState = CryptocurrencyLoaded(
        cryptocurrencies: [],
        connectionStatus: ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: DateTime.now(),
        ),
        lastUpdated: DateTime.now(),
      );

      // Act - Use StateUpdater to check for changes
      final updater = StateUpdater(initialState);
      updater.update(
        'isConnected',
        true, // Same value
        (state) => state.connectionStatus.isConnected,
      );

      final newState = updater.build((changes) => initialState.copyWith());

      // Assert - Should return the same instance since no changes were made
      expect(identical(initialState, newState), isTrue);
      expect(updater.hasChanges, isFalse);
    });

    test('should use performance monitoring effectively', () {
      // Arrange & Act
      final result = PerformanceMonitor.measure('test_operation', () {
        // Simulate some work
        var sum = 0;
        for (int i = 0; i < 1000; i++) {
          sum += i;
        }
        return sum;
      });

      // Assert
      expect(result, equals(499500)); // Sum of 0 to 999

      final metric = PerformanceMonitor.getMetric('test_operation');
      expect(metric, isNotNull);
      expect(metric!.name, equals('test_operation'));
      expect(metric.duration, isNotNull);
    });
  });
}
