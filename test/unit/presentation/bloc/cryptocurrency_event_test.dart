import 'package:test/test.dart';
import 'package:crypto_dashboard/presentation/bloc/cryptocurrency_event.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';

void main() {
  group('CryptocurrencyEvent Tests', () {
    late PriceUpdateEvent testPriceUpdate;
    late VolumeAlert testVolumeAlert;
    late ConnectionStatus testConnectionStatus;

    setUp(() {
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

      testConnectionStatus = ConnectionStatus(
        isConnected: true,
        statusMessage: 'Connected',
        lastUpdate: DateTime(2024, 1, 1, 12, 0, 0),
      );
    });

    group('LoadInitialData', () {
      test('should create event correctly', () {
        const event = LoadInitialData();
        expect(event, isA<LoadInitialData>());
        expect(event.props, isEmpty);
      });

      test('should be equal to another LoadInitialData event', () {
        const event1 = LoadInitialData();
        const event2 = LoadInitialData();
        expect(event1, equals(event2));
      });
    });

    group('StartRealTimeUpdates', () {
      test('should create event correctly', () {
        const event = StartRealTimeUpdates();
        expect(event, isA<StartRealTimeUpdates>());
        expect(event.props, isEmpty);
      });

      test('should be equal to another StartRealTimeUpdates event', () {
        const event1 = StartRealTimeUpdates();
        const event2 = StartRealTimeUpdates();
        expect(event1, equals(event2));
      });
    });

    group('StopRealTimeUpdates', () {
      test('should create event correctly', () {
        const event = StopRealTimeUpdates();
        expect(event, isA<StopRealTimeUpdates>());
        expect(event.props, isEmpty);
      });

      test('should be equal to another StopRealTimeUpdates event', () {
        const event1 = StopRealTimeUpdates();
        const event2 = StopRealTimeUpdates();
        expect(event1, equals(event2));
      });
    });

    group('RefreshData', () {
      test('should create event correctly', () {
        const event = RefreshData();
        expect(event, isA<RefreshData>());
        expect(event.props, isEmpty);
      });

      test('should be equal to another RefreshData event', () {
        const event1 = RefreshData();
        const event2 = RefreshData();
        expect(event1, equals(event2));
      });
    });

    group('PriceUpdated', () {
      test('should create event correctly', () {
        final event = PriceUpdated(testPriceUpdate);
        expect(event, isA<PriceUpdated>());
        expect(event.update, equals(testPriceUpdate));
        expect(event.props, equals([testPriceUpdate]));
      });

      test('should be equal when price updates are the same', () {
        final event1 = PriceUpdated(testPriceUpdate);
        final event2 = PriceUpdated(testPriceUpdate);
        expect(event1, equals(event2));
      });

      test('should not be equal when price updates are different', () {
        final differentUpdate = PriceUpdateEvent(
          symbol: 'ETH',
          newPrice: 3100.0,
          priceChange: 100.0,
          timestamp: DateTime(2024, 1, 1, 12, 1, 0),
        );

        final event1 = PriceUpdated(testPriceUpdate);
        final event2 = PriceUpdated(differentUpdate);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('VolumeAlertReceived', () {
      test('should create event correctly', () {
        final event = VolumeAlertReceived(testVolumeAlert);
        expect(event, isA<VolumeAlertReceived>());
        expect(event.alert, equals(testVolumeAlert));
        expect(event.props, equals([testVolumeAlert]));
      });

      test('should be equal when volume alerts are the same', () {
        final event1 = VolumeAlertReceived(testVolumeAlert);
        final event2 = VolumeAlertReceived(testVolumeAlert);
        expect(event1, equals(event2));
      });

      test('should not be equal when volume alerts are different', () {
        final differentAlert = VolumeAlert(
          symbol: 'ETH',
          currentVolume: 750000.0,
          previousVolume: 500000.0,
          spikePercentage: 0.5,
        );

        final event1 = VolumeAlertReceived(testVolumeAlert);
        final event2 = VolumeAlertReceived(differentAlert);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('ConnectionStatusChanged', () {
      test('should create event correctly', () {
        final event = ConnectionStatusChanged(testConnectionStatus);
        expect(event, isA<ConnectionStatusChanged>());
        expect(event.status, equals(testConnectionStatus));
        expect(event.props, equals([testConnectionStatus]));
      });

      test('should be equal when connection statuses are the same', () {
        final event1 = ConnectionStatusChanged(testConnectionStatus);
        final event2 = ConnectionStatusChanged(testConnectionStatus);
        expect(event1, equals(event2));
      });

      test('should not be equal when connection statuses are different', () {
        final differentStatus = testConnectionStatus.copyWith(
          isConnected: false,
          statusMessage: 'Disconnected',
        );

        final event1 = ConnectionStatusChanged(testConnectionStatus);
        final event2 = ConnectionStatusChanged(differentStatus);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('DismissVolumeAlert', () {
      test('should create event correctly', () {
        const event = DismissVolumeAlert('BTC');
        expect(event, isA<DismissVolumeAlert>());
        expect(event.symbol, equals('BTC'));
        expect(event.props, equals(['BTC']));
      });

      test('should be equal when symbols are the same', () {
        const event1 = DismissVolumeAlert('BTC');
        const event2 = DismissVolumeAlert('BTC');
        expect(event1, equals(event2));
      });

      test('should not be equal when symbols are different', () {
        const event1 = DismissVolumeAlert('BTC');
        const event2 = DismissVolumeAlert('ETH');
        expect(event1, isNot(equals(event2)));
      });
    });

    group('AppLifecycleChanged', () {
      test('should create event correctly for foreground', () {
        const event = AppLifecycleChanged(true);
        expect(event, isA<AppLifecycleChanged>());
        expect(event.isInForeground, isTrue);
        expect(event.props, equals([true]));
      });

      test('should create event correctly for background', () {
        const event = AppLifecycleChanged(false);
        expect(event, isA<AppLifecycleChanged>());
        expect(event.isInForeground, isFalse);
        expect(event.props, equals([false]));
      });

      test('should be equal when lifecycle states are the same', () {
        const event1 = AppLifecycleChanged(true);
        const event2 = AppLifecycleChanged(true);
        expect(event1, equals(event2));
      });

      test('should not be equal when lifecycle states are different', () {
        const event1 = AppLifecycleChanged(true);
        const event2 = AppLifecycleChanged(false);
        expect(event1, isNot(equals(event2)));
      });
    });

    group('Event Inheritance', () {
      test('all events should extend CryptocurrencyEvent', () {
        const loadEvent = LoadInitialData();
        const startEvent = StartRealTimeUpdates();
        const stopEvent = StopRealTimeUpdates();
        const refreshEvent = RefreshData();
        final priceEvent = PriceUpdated(testPriceUpdate);
        final volumeEvent = VolumeAlertReceived(testVolumeAlert);
        final connectionEvent = ConnectionStatusChanged(testConnectionStatus);
        const dismissEvent = DismissVolumeAlert('BTC');
        const lifecycleEvent = AppLifecycleChanged(true);

        expect(loadEvent, isA<CryptocurrencyEvent>());
        expect(startEvent, isA<CryptocurrencyEvent>());
        expect(stopEvent, isA<CryptocurrencyEvent>());
        expect(refreshEvent, isA<CryptocurrencyEvent>());
        expect(priceEvent, isA<CryptocurrencyEvent>());
        expect(volumeEvent, isA<CryptocurrencyEvent>());
        expect(connectionEvent, isA<CryptocurrencyEvent>());
        expect(dismissEvent, isA<CryptocurrencyEvent>());
        expect(lifecycleEvent, isA<CryptocurrencyEvent>());
      });
    });

    group('Event Properties', () {
      test('events with data should have correct props', () {
        final priceEvent = PriceUpdated(testPriceUpdate);
        final volumeEvent = VolumeAlertReceived(testVolumeAlert);
        final connectionEvent = ConnectionStatusChanged(testConnectionStatus);
        const dismissEvent = DismissVolumeAlert('BTC');
        const lifecycleEvent = AppLifecycleChanged(true);

        expect(priceEvent.props.length, equals(1));
        expect(priceEvent.props.first, equals(testPriceUpdate));

        expect(volumeEvent.props.length, equals(1));
        expect(volumeEvent.props.first, equals(testVolumeAlert));

        expect(connectionEvent.props.length, equals(1));
        expect(connectionEvent.props.first, equals(testConnectionStatus));

        expect(dismissEvent.props.length, equals(1));
        expect(dismissEvent.props.first, equals('BTC'));

        expect(lifecycleEvent.props.length, equals(1));
        expect(lifecycleEvent.props.first, equals(true));
      });

      test('events without data should have empty props', () {
        const loadEvent = LoadInitialData();
        const startEvent = StartRealTimeUpdates();
        const stopEvent = StopRealTimeUpdates();
        const refreshEvent = RefreshData();

        expect(loadEvent.props, isEmpty);
        expect(startEvent.props, isEmpty);
        expect(stopEvent.props, isEmpty);
        expect(refreshEvent.props, isEmpty);
      });
    });
  });
}
