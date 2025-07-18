import 'package:test/test.dart';
import 'package:crypto_dashboard/presentation/bloc/cryptocurrency_state.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';

void main() {
  group('CryptocurrencyState Tests', () {
    late List<Cryptocurrency> testCryptocurrencies;
    late ConnectionStatus testConnectionStatus;
    late VolumeAlert testVolumeAlert;

    setUp(() {
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

      testVolumeAlert = VolumeAlert(
        symbol: 'BTC',
        currentVolume: 1500000.0,
        previousVolume: 1000000.0,
        spikePercentage: 0.5,
      );
    });

    group('CryptocurrencyInitial', () {
      test('should create initial state correctly', () {
        const state = CryptocurrencyInitial();
        expect(state, isA<CryptocurrencyInitial>());
        expect(state.props, isEmpty);
      });

      test('should be equal to another initial state', () {
        const state1 = CryptocurrencyInitial();
        const state2 = CryptocurrencyInitial();
        expect(state1, equals(state2));
      });
    });

    group('CryptocurrencyLoading', () {
      test('should create loading state without message', () {
        const state = CryptocurrencyLoading();
        expect(state, isA<CryptocurrencyLoading>());
        expect(state.message, isNull);
      });

      test('should create loading state with message', () {
        const state = CryptocurrencyLoading(message: 'Loading data...');
        expect(state.message, equals('Loading data...'));
      });

      test('should be equal when messages are the same', () {
        const state1 = CryptocurrencyLoading(message: 'Loading...');
        const state2 = CryptocurrencyLoading(message: 'Loading...');
        expect(state1, equals(state2));
      });

      test('should not be equal when messages are different', () {
        const state1 = CryptocurrencyLoading(message: 'Loading...');
        const state2 = CryptocurrencyLoading(message: 'Different message');
        expect(state1, isNot(equals(state2)));
      });
    });

    group('CryptocurrencyLoaded', () {
      test('should create loaded state correctly', () {
        final state = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        expect(state, isA<CryptocurrencyLoaded>());
        expect(state.cryptocurrencies.length, equals(2));
        expect(state.cryptocurrencies.first.symbol, equals('BTC'));
        expect(state.connectionStatus.isConnected, isTrue);
        expect(state.activeAlerts, isEmpty);
        expect(state.isRefreshing, isFalse);
      });

      test('should create copy with updated values', () {
        final originalState = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        final newConnectionStatus = testConnectionStatus.copyWith(
          isConnected: false,
          statusMessage: 'Disconnected',
        );

        final newState = originalState.copyWith(
          connectionStatus: newConnectionStatus,
          isRefreshing: true,
        );

        expect(newState.connectionStatus.isConnected, isFalse);
        expect(newState.connectionStatus.statusMessage, equals('Disconnected'));
        expect(newState.isRefreshing, isTrue);
        expect(
          newState.cryptocurrencies,
          equals(originalState.cryptocurrencies),
        );
      });

      test('should update single cryptocurrency correctly', () {
        final originalState = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        final updatedBtc = testCryptocurrencies.first.copyWith(price: 55000.0);
        final newState = originalState.updateCryptocurrency(updatedBtc);

        expect(newState.cryptocurrencies.first.price, equals(55000.0));
        expect(newState.cryptocurrencies.first.symbol, equals('BTC'));
        expect(newState.cryptocurrencies.length, equals(2));
        expect(
          newState.cryptocurrencies.last.price,
          equals(3000.0),
        ); // ETH unchanged
      });

      test('should update multiple cryptocurrencies correctly', () {
        final originalState = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        final updatedBtc = testCryptocurrencies.first.copyWith(price: 55000.0);
        final updatedEth = testCryptocurrencies.last.copyWith(price: 3500.0);

        final updates = {'BTC': updatedBtc, 'ETH': updatedEth};

        final newState = originalState.updateCryptocurrencies(updates);

        expect(newState.cryptocurrencies.first.price, equals(55000.0));
        expect(newState.cryptocurrencies.last.price, equals(3500.0));
        expect(newState.cryptocurrencies.length, equals(2));
      });

      test('should add volume alert correctly', () {
        final originalState = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        final newState = originalState.addVolumeAlert(testVolumeAlert);

        expect(newState.activeAlerts.length, equals(1));
        expect(newState.activeAlerts['BTC'], equals(testVolumeAlert));
        expect(
          newState.cryptocurrencies,
          equals(originalState.cryptocurrencies),
        );
      });

      test('should not add duplicate volume alert', () {
        final originalState = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          activeAlerts: {'BTC': testVolumeAlert},
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        final newState = originalState.addVolumeAlert(testVolumeAlert);

        // Should return the same instance since alert is identical
        expect(identical(originalState, newState), isTrue);
      });

      test('should remove volume alert correctly', () {
        final cryptoWithSpike = testCryptocurrencies.first.copyWith(
          hasVolumeSpike: true,
        );
        final cryptosWithSpike = [cryptoWithSpike, testCryptocurrencies.last];

        final originalState = CryptocurrencyLoaded(
          cryptocurrencies: cryptosWithSpike,
          connectionStatus: testConnectionStatus,
          activeAlerts: {'BTC': testVolumeAlert},
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        final newState = originalState.removeVolumeAlert('BTC');

        expect(newState.activeAlerts.length, equals(0));
        expect(newState.cryptocurrencies.first.hasVolumeSpike, isFalse);
      });

      test('should not remove non-existent volume alert', () {
        final originalState = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        final newState = originalState.removeVolumeAlert('UNKNOWN');

        // Should return the same instance since alert doesn't exist
        expect(identical(originalState, newState), isTrue);
      });

      test('should get cryptocurrencies with volume spikes', () {
        final cryptoWithSpike = testCryptocurrencies.first.copyWith(
          hasVolumeSpike: true,
        );
        final cryptosWithSpike = [cryptoWithSpike, testCryptocurrencies.last];

        final state = CryptocurrencyLoaded(
          cryptocurrencies: cryptosWithSpike,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        final spikes = state.cryptocurrenciesWithVolumeSpikes;
        expect(spikes.length, equals(1));
        expect(spikes.first.symbol, equals('BTC'));
        expect(spikes.first.hasVolumeSpike, isTrue);
      });

      test('should get connected status', () {
        final state = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        expect(state.isConnected, isTrue);

        final disconnectedState = state.copyWith(
          connectionStatus: testConnectionStatus.copyWith(isConnected: false),
        );

        expect(disconnectedState.isConnected, isFalse);
      });

      test('should get active alert count', () {
        final state = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          activeAlerts: {'BTC': testVolumeAlert},
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        expect(state.activeAlertCount, equals(1));
      });

      test('should use efficient equality comparison', () {
        final state1 = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        final state2 = CryptocurrencyLoaded(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        expect(state1.isEqualTo(state2), isTrue);
        expect(state1, equals(state2));
      });
    });

    group('CryptocurrencyError', () {
      test('should create error state correctly', () {
        const state = CryptocurrencyError(
          message: 'Network error',
          details: 'Connection timeout',
          canRetry: true,
        );

        expect(state, isA<CryptocurrencyError>());
        expect(state.message, equals('Network error'));
        expect(state.details, equals('Connection timeout'));
        expect(state.canRetry, isTrue);
        expect(state.previousData, isNull);
      });

      test('should create error state with previous data', () {
        final state = CryptocurrencyError(
          message: 'Update failed',
          details: 'Server error',
          canRetry: true,
          previousData: testCryptocurrencies,
        );

        expect(state.message, equals('Update failed'));
        expect(state.previousData, equals(testCryptocurrencies));
      });

      test('should be equal when all properties match', () {
        const state1 = CryptocurrencyError(
          message: 'Error',
          details: 'Details',
          canRetry: false,
        );

        const state2 = CryptocurrencyError(
          message: 'Error',
          details: 'Details',
          canRetry: false,
        );

        expect(state1, equals(state2));
      });
    });

    group('CryptocurrencyRefreshing', () {
      test('should create refreshing state correctly', () {
        final state = CryptocurrencyRefreshing(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        expect(state, isA<CryptocurrencyRefreshing>());
        expect(state, isA<CryptocurrencyLoaded>());
        expect(state.isRefreshing, isTrue);
        expect(state.cryptocurrencies, equals(testCryptocurrencies));
      });

      test('should inherit from CryptocurrencyLoaded', () {
        final state = CryptocurrencyRefreshing(
          cryptocurrencies: testCryptocurrencies,
          connectionStatus: testConnectionStatus,
          lastUpdated: DateTime(2024, 1, 1, 12, 0, 0),
        );

        // Should have all the functionality of CryptocurrencyLoaded
        expect(state.isConnected, isTrue);
        expect(state.activeAlertCount, equals(0));
        expect(state.cryptocurrenciesWithVolumeSpikes, isEmpty);
      });
    });
  });
}
