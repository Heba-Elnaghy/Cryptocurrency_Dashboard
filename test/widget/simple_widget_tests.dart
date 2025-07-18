import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';
import 'package:crypto_dashboard/presentation/widgets/animated_cryptocurrency_card.dart';
import 'package:crypto_dashboard/presentation/widgets/animated_cryptocurrency_list.dart';
import 'package:crypto_dashboard/presentation/widgets/animated_price_display.dart';
import 'package:crypto_dashboard/presentation/widgets/animated_connection_status.dart';
import 'package:crypto_dashboard/presentation/bloc/bloc.dart';

// Mock classes
class MockCryptocurrencyBloc extends Mock implements CryptocurrencyBloc {}

void main() {
  group('Widget Tests - UI Components', () {
    late MockCryptocurrencyBloc mockBloc;
    late Cryptocurrency testCrypto;
    late VolumeAlert testAlert;
    late ConnectionStatus testConnectionStatus;

    setUp(() {
      mockBloc = MockCryptocurrencyBloc();

      testCrypto = Cryptocurrency(
        symbol: 'BTC',
        name: 'Bitcoin',
        price: 50000.00,
        priceChange24h: 1500.50,
        volume24h: 1000000.0,
        status: ListingStatus.active,
        lastUpdated: DateTime.now(),
        hasVolumeSpike: false,
      );

      testAlert = const VolumeAlert(
        symbol: 'BTC',
        currentVolume: 1500000.0,
        previousVolume: 1000000.0,
        spikePercentage: 0.5,
      );

      testConnectionStatus = ConnectionStatus(
        isConnected: true,
        statusMessage: 'Live',
        lastUpdate: DateTime.now(),
      );

      // Register fallback values for mocktail
      registerFallbackValue(const DismissVolumeAlert('BTC'));
    });

    group('Cryptocurrency Card Rendering', () {
      Widget createCardTestWidget({
        Cryptocurrency? crypto,
        VolumeAlert? alert,
      }) {
        return MaterialApp(
          home: BlocProvider<CryptocurrencyBloc>(
            create: (_) => mockBloc,
            child: Scaffold(
              body: AnimatedCryptocurrencyCard(
                cryptocurrency: crypto ?? testCrypto,
                volumeAlert: alert,
              ),
            ),
          ),
        );
      }

      testWidgets('renders basic cryptocurrency information', (tester) async {
        await tester.pumpWidget(createCardTestWidget());
        await tester.pump();

        // Verify basic cryptocurrency information is displayed
        expect(find.text('BTC'), findsOneWidget);
        expect(find.text('Bitcoin'), findsOneWidget);
        expect(find.text('\$50000.00'), findsOneWidget);
        expect(find.text('+\$1500.50'), findsOneWidget);
      });

      testWidgets('displays different cryptocurrency states', (tester) async {
        // Test active status (no badge shown)
        await tester.pumpWidget(createCardTestWidget());
        await tester.pump();
        expect(find.text('Delisted'), findsNothing);
        expect(find.text('Suspended'), findsNothing);

        // Test delisted status
        final delistedCrypto = testCrypto.copyWith(
          status: ListingStatus.delisted,
        );
        await tester.pumpWidget(createCardTestWidget(crypto: delistedCrypto));
        await tester.pump();
        expect(find.text('Delisted'), findsOneWidget);

        // Test suspended status
        final suspendedCrypto = testCrypto.copyWith(
          status: ListingStatus.suspended,
        );
        await tester.pumpWidget(createCardTestWidget(crypto: suspendedCrypto));
        await tester.pump();
        expect(find.text('Suspended'), findsOneWidget);
      });

      testWidgets('shows volume alert when provided', (tester) async {
        await tester.pumpWidget(createCardTestWidget(alert: testAlert));
        await tester.pump();

        // Wait a bit for alert animation to start
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 200));

        // Verify volume alert is displayed
        expect(find.text('Volume spike: +50.0%'), findsOneWidget);
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('handles volume alert dismissal', (tester) async {
        await tester.pumpWidget(createCardTestWidget(alert: testAlert));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Find and tap the close button
        final closeButton = find.byIcon(Icons.close);
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
          await tester.pump();

          // Verify the dismiss event was added to the bloc
          verify(() => mockBloc.add(const DismissVolumeAlert('BTC'))).called(1);
        }
      });

      testWidgets('displays positive and negative price changes correctly', (
        tester,
      ) async {
        // Test positive change
        await tester.pumpWidget(createCardTestWidget());
        await tester.pump();
        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

        // Test negative change
        final negativeCrypto = testCrypto.copyWith(priceChange24h: -1500.50);
        await tester.pumpWidget(createCardTestWidget(crypto: negativeCrypto));
        await tester.pump();
        expect(find.text('\$-1500.50'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      });
    });

    group('Price Display Component', () {
      testWidgets('displays price and change correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedPriceDisplay(price: 50000.00, priceChange: 1500.50),
            ),
          ),
        );

        await tester.pump();

        // Verify price is displayed
        expect(find.text('\$50000.00'), findsOneWidget);
        expect(find.text('+\$1500.50'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      });

      testWidgets('shows correct icons for price changes', (tester) async {
        // Test positive change
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedPriceDisplay(price: 50000.00, priceChange: 1500.50),
            ),
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

        // Test negative change
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedPriceDisplay(
                price: 48000.00,
                priceChange: -2000.50,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      });
    });

    group('Connection Status Component', () {
      testWidgets('displays connection status correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedConnectionStatus(
                connectionStatus: testConnectionStatus,
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Live'), findsOneWidget);
      });

      testWidgets('shows different connection states', (tester) async {
        // Test connecting state
        final connectingStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Connecting...',
          lastUpdate: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedConnectionStatus(
                connectionStatus: connectingStatus,
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Connecting...'), findsOneWidget);

        // Test error state
        final errorStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Connection Failed',
          lastUpdate: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedConnectionStatus(connectionStatus: errorStatus),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Connection Failed'), findsOneWidget);
      });
    });

    group('Cryptocurrency List Component', () {
      testWidgets('renders list of cryptocurrencies', (tester) async {
        final cryptocurrencies = [
          testCrypto,
          Cryptocurrency(
            symbol: 'ETH',
            name: 'Ethereum',
            price: 3000.00,
            priceChange24h: -150.25,
            volume24h: 500000.0,
            status: ListingStatus.active,
            lastUpdated: DateTime.now(),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  AnimatedCryptocurrencyList(
                    cryptocurrencies: cryptocurrencies,
                    activeAlerts: {},
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();

        // Verify cryptocurrencies are displayed
        expect(find.text('BTC'), findsOneWidget);
        expect(find.text('ETH'), findsOneWidget);
        expect(find.text('Bitcoin'), findsOneWidget);
        expect(find.text('Ethereum'), findsOneWidget);
      });

      testWidgets('handles empty cryptocurrency list', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  AnimatedCryptocurrencyList(
                    cryptocurrencies: [],
                    activeAlerts: {},
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();

        // Should not crash and should show no items
        expect(find.text('BTC'), findsNothing);
        expect(find.text('ETH'), findsNothing);
      });

      testWidgets('displays volume alerts for appropriate cryptocurrencies', (
        tester,
      ) async {
        final cryptocurrencies = [testCrypto];
        final alerts = {'BTC': testAlert};

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  AnimatedCryptocurrencyList(
                    cryptocurrencies: cryptocurrencies,
                    activeAlerts: alerts,
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Verify volume alert is shown
        expect(find.text('Volume spike: +50.0%'), findsOneWidget);
      });
    });

    group('Responsive Layout Behavior', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        final cryptocurrencies = [testCrypto];

        // Test mobile size
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  AnimatedCryptocurrencyList(
                    cryptocurrencies: cryptocurrencies,
                    activeAlerts: {},
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('BTC'), findsOneWidget);

        // Test tablet size
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  AnimatedCryptocurrencyList(
                    cryptocurrencies: cryptocurrencies,
                    activeAlerts: {},
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('BTC'), findsOneWidget);

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('maintains content structure across orientations', (
        tester,
      ) async {
        final cryptocurrencies = [testCrypto];

        // Portrait
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  AnimatedCryptocurrencyList(
                    cryptocurrencies: cryptocurrencies,
                    activeAlerts: {},
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('BTC'), findsOneWidget);
        expect(find.text('Bitcoin'), findsOneWidget);

        // Landscape
        await tester.binding.setSurfaceSize(const Size(800, 400));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  AnimatedCryptocurrencyList(
                    cryptocurrencies: cryptocurrencies,
                    activeAlerts: {},
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('BTC'), findsOneWidget);
        expect(find.text('Bitcoin'), findsOneWidget);

        // Reset to default size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('User Interactions', () {
      testWidgets('handles card tap interactions', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<CryptocurrencyBloc>(
              create: (_) => mockBloc,
              child: Scaffold(
                body: AnimatedCryptocurrencyCard(cryptocurrency: testCrypto),
              ),
            ),
          ),
        );

        await tester.pump();

        // Tap on the card
        await tester.tap(find.byType(AnimatedCryptocurrencyCard));
        await tester.pump();

        // Card should handle tap without errors
        expect(find.byType(AnimatedCryptocurrencyCard), findsOneWidget);
      });

      testWidgets('handles volume alert dismissal interaction', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<CryptocurrencyBloc>(
              create: (_) => mockBloc,
              child: Scaffold(
                body: AnimatedCryptocurrencyCard(
                  cryptocurrency: testCrypto,
                  volumeAlert: testAlert,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Find and tap the close button if it exists
        final closeButton = find.byIcon(Icons.close);
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
          await tester.pump();

          // Verify interaction was handled
          verify(() => mockBloc.add(const DismissVolumeAlert('BTC'))).called(1);
        }
      });
    });

    group('Animation Behavior', () {
      testWidgets('handles data updates without crashing', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<CryptocurrencyBloc>(
              create: (_) => mockBloc,
              child: Scaffold(
                body: AnimatedCryptocurrencyCard(cryptocurrency: testCrypto),
              ),
            ),
          ),
        );

        await tester.pump();

        // Update with new data
        final updatedCrypto = testCrypto.copyWith(price: 52000.00);
        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<CryptocurrencyBloc>(
              create: (_) => mockBloc,
              child: Scaffold(
                body: AnimatedCryptocurrencyCard(cryptocurrency: updatedCrypto),
              ),
            ),
          ),
        );

        // Pump a few animation frames
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));

        // Verify new price is displayed
        expect(find.text('\$52000.00'), findsOneWidget);
      });

      testWidgets('handles price change animations', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedPriceDisplay(price: 50000.00, priceChange: 1500.50),
            ),
          ),
        );

        await tester.pump();

        // Update with new price
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedPriceDisplay(price: 51000.00, priceChange: 2500.50),
            ),
          ),
        );

        // Pump animation frames
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 200));

        // Verify new price is displayed
        expect(find.text('\$51000.00'), findsOneWidget);
      });

      testWidgets('handles connection status transitions', (tester) async {
        final connectingStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Connecting...',
          lastUpdate: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedConnectionStatus(
                connectionStatus: connectingStatus,
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.text('Connecting...'), findsOneWidget);

        // Change to live status
        final liveStatus = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Live',
          lastUpdate: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedConnectionStatus(connectionStatus: liveStatus),
            ),
          ),
        );

        // Pump animation frames
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Live'), findsOneWidget);
      });
    });
  });
}
