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
  group('Animation and Interaction Tests', () {
    late MockCryptocurrencyBloc mockBloc;

    setUp(() {
      mockBloc = MockCryptocurrencyBloc();
      registerFallbackValue(const DismissVolumeAlert('BTC'));
    });

    group('Price Display Animations', () {
      testWidgets('animates price changes with flash effect', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedPriceDisplay(price: 50000.00, priceChange: 1500.50),
            ),
          ),
        );

        // Initial state
        expect(find.text('\$50000.00'), findsOneWidget);
        expect(find.text('+\$1500.50'), findsOneWidget);

        // Update with new price to trigger animation
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedPriceDisplay(price: 51000.00, priceChange: 2500.50),
            ),
          ),
        );

        // Pump animation frames
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 300));

        // Verify new price is displayed
        await tester.pumpAndSettle();
        expect(find.text('\$51000.00'), findsOneWidget);
      });

      testWidgets('shows different colors for positive and negative changes', (
        tester,
      ) async {
        // Test positive change
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedPriceDisplay(price: 50000.00, priceChange: 1500.50),
            ),
          ),
        );

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

        expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      });

      testWidgets(
        'scales animation intensity based on price change magnitude',
        (tester) async {
          // Small price change
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AnimatedPriceDisplay(price: 50000.00, priceChange: 10.00),
              ),
            ),
          );

          await tester.pump();

          // Large price change
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AnimatedPriceDisplay(
                  price: 55000.00,
                  priceChange: 5000.00,
                ),
              ),
            ),
          );

          // Pump animation frames to see scaling effect
          for (int i = 0; i < 10; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }

          await tester.pumpAndSettle();
          expect(find.text('\$55000.00'), findsOneWidget);
        },
      );

      testWidgets('maintains continuous pulse animation', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedPriceDisplay(price: 50000.00, priceChange: 1500.50),
            ),
          ),
        );

        // Let pulse animation run for several cycles
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Widget should still be there and functional
        expect(find.text('\$50000.00'), findsOneWidget);
      });
    });

    group('Connection Status Animations', () {
      testWidgets('animates connection status transitions', (tester) async {
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
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        expect(find.text('Live'), findsOneWidget);
      });

      testWidgets('shows spinner animation for connecting states', (
        tester,
      ) async {
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

        // Let spinner animation run
        for (int i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('Connecting...'), findsOneWidget);
      });

      testWidgets('shows pulse effect for connecting states', (tester) async {
        final connectingStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Reconnecting...',
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

        // Let pulse animation run
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(find.text('Reconnecting...'), findsOneWidget);
      });

      testWidgets('handles rapid status changes smoothly', (tester) async {
        final statuses = [
          ConnectionStatus(
            isConnected: false,
            statusMessage: 'Connecting...',
            lastUpdate: DateTime.now(),
          ),
          ConnectionStatus(
            isConnected: true,
            statusMessage: 'Live',
            lastUpdate: DateTime.now(),
          ),
          ConnectionStatus(
            isConnected: false,
            statusMessage: 'Reconnecting...',
            lastUpdate: DateTime.now(),
          ),
        ];

        for (final status in statuses) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AnimatedConnectionStatus(connectionStatus: status),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 50));
          expect(find.text(status.statusMessage), findsOneWidget);
        }
      });
    });

    group('Card Animations', () {
      Widget createCardTestWidget(Cryptocurrency crypto, {VolumeAlert? alert}) {
        return MaterialApp(
          home: BlocProvider<CryptocurrencyBloc>(
            create: (_) => mockBloc,
            child: Scaffold(
              body: AnimatedCryptocurrencyCard(
                cryptocurrency: crypto,
                volumeAlert: alert,
              ),
            ),
          ),
        );
      }

      testWidgets('animates card updates when data changes', (tester) async {
        final crypto = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.00,
          priceChange24h: 1500.50,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
        );

        await tester.pumpWidget(createCardTestWidget(crypto));
        await tester.pumpAndSettle();

        // Update with new data
        final updatedCrypto = crypto.copyWith(price: 52000.00);
        await tester.pumpWidget(createCardTestWidget(updatedCrypto));

        // Pump animation frames
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();
        expect(find.text('\$52000.00'), findsOneWidget);
      });

      testWidgets('shows shimmer effect for significant updates', (
        tester,
      ) async {
        final crypto = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.00,
          priceChange24h: 1500.50,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
        );

        await tester.pumpWidget(createCardTestWidget(crypto));
        await tester.pumpAndSettle();

        // Significant price change (>5%)
        final significantUpdate = crypto.copyWith(price: 53000.00);
        await tester.pumpWidget(createCardTestWidget(significantUpdate));

        // Pump shimmer animation frames
        for (int i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }

        expect(find.byType(AnimatedCryptocurrencyCard), findsOneWidget);
      });

      testWidgets('animates volume alert appearance', (tester) async {
        final crypto = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.00,
          priceChange24h: 1500.50,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
        );

        // Start without alert
        await tester.pumpWidget(createCardTestWidget(crypto));
        await tester.pumpAndSettle();

        expect(find.text('Volume spike:'), findsNothing);

        // Add alert
        const alert = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        await tester.pumpWidget(createCardTestWidget(crypto, alert: alert));

        // Pump alert animation frames
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();
        expect(find.text('Volume spike: +50.0%'), findsOneWidget);
      });

      testWidgets('animates volume alert dismissal', (tester) async {
        final crypto = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.00,
          priceChange24h: 1500.50,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
        );

        const alert = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        // Start with alert
        await tester.pumpWidget(createCardTestWidget(crypto, alert: alert));
        await tester.pumpAndSettle();

        expect(find.text('Volume spike: +50.0%'), findsOneWidget);

        // Remove alert
        await tester.pumpWidget(createCardTestWidget(crypto));

        // Pump dismissal animation frames
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();
        expect(find.text('Volume spike:'), findsNothing);
      });

      testWidgets('handles status change animations', (tester) async {
        final crypto = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.00,
          priceChange24h: 1500.50,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
        );

        await tester.pumpWidget(createCardTestWidget(crypto));
        await tester.pumpAndSettle();

        // Change to delisted status
        final delistedCrypto = crypto.copyWith(status: ListingStatus.delisted);
        await tester.pumpWidget(createCardTestWidget(delistedCrypto));

        // Pump status animation frames
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();
        expect(find.text('Delisted'), findsOneWidget);
      });
    });

    group('List Animations', () {
      testWidgets('performs staggered animation on initial load', (
        tester,
      ) async {
        final cryptocurrencies = [
          Cryptocurrency(
            symbol: 'BTC',
            name: 'Bitcoin',
            price: 50000.00,
            priceChange24h: 1500.50,
            volume24h: 1000000.0,
            status: ListingStatus.active,
            lastUpdated: DateTime.now(),
          ),
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
                    isInitialLoad: true,
                  ),
                ],
              ),
            ),
          ),
        );

        // Pump staggered animation frames
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.pumpAndSettle();

        expect(find.text('BTC'), findsOneWidget);
        expect(find.text('ETH'), findsOneWidget);
      });

      testWidgets('animates item updates smoothly', (tester) async {
        final cryptocurrencies = [
          Cryptocurrency(
            symbol: 'BTC',
            name: 'Bitcoin',
            price: 50000.00,
            priceChange24h: 1500.50,
            volume24h: 1000000.0,
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

        await tester.pumpAndSettle();

        // Update with new data
        final updatedCryptocurrencies = [
          cryptocurrencies[0].copyWith(price: 51000.00),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  AnimatedCryptocurrencyList(
                    cryptocurrencies: updatedCryptocurrencies,
                    activeAlerts: {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Pump update animation frames
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        await tester.pumpAndSettle();
        expect(find.text('\$51000.00'), findsOneWidget);
      });

      testWidgets('handles adding new items with animation', (tester) async {
        final initialCryptocurrencies = [
          Cryptocurrency(
            symbol: 'BTC',
            name: 'Bitcoin',
            price: 50000.00,
            priceChange24h: 1500.50,
            volume24h: 1000000.0,
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
                    cryptocurrencies: initialCryptocurrencies,
                    activeAlerts: {},
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('BTC'), findsOneWidget);

        // Add new item
        final expandedCryptocurrencies = [
          ...initialCryptocurrencies,
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
                    cryptocurrencies: expandedCryptocurrencies,
                    activeAlerts: {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Pump new item animation frames
        for (int i = 0; i < 15; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.pumpAndSettle();
        expect(find.text('ETH'), findsOneWidget);
      });
    });

    group('User Interactions', () {
      testWidgets('handles volume alert dismissal interaction', (tester) async {
        final crypto = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.00,
          priceChange24h: 1500.50,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
        );

        const alert = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<CryptocurrencyBloc>(
              create: (_) => mockBloc,
              child: Scaffold(
                body: AnimatedCryptocurrencyCard(
                  cryptocurrency: crypto,
                  volumeAlert: alert,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap the close button
        final closeButton = find.byIcon(Icons.close);
        expect(closeButton, findsOneWidget);

        await tester.tap(closeButton);
        await tester.pump();

        // Verify interaction was handled
        verify(() => mockBloc.add(const DismissVolumeAlert('BTC'))).called(1);
      });

      testWidgets('handles tap interactions on cards', (tester) async {
        final crypto = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.00,
          priceChange24h: 1500.50,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<CryptocurrencyBloc>(
              create: (_) => mockBloc,
              child: Scaffold(
                body: AnimatedCryptocurrencyCard(cryptocurrency: crypto),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap on the card
        await tester.tap(find.byType(AnimatedCryptocurrencyCard));
        await tester.pump();

        // Card should handle tap without errors
        expect(find.byType(AnimatedCryptocurrencyCard), findsOneWidget);
      });

      testWidgets('maintains responsiveness during animations', (tester) async {
        final crypto = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.00,
          priceChange24h: 1500.50,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
        );

        const alert = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BlocProvider<CryptocurrencyBloc>(
              create: (_) => mockBloc,
              child: Scaffold(
                body: AnimatedCryptocurrencyCard(
                  cryptocurrency: crypto,
                  volumeAlert: alert,
                ),
              ),
            ),
          ),
        );

        // Start animations
        await tester.pump(const Duration(milliseconds: 100));

        // Try to interact during animation
        final closeButton = find.byIcon(Icons.close);
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
          await tester.pump();

          // Should still be responsive
          verify(() => mockBloc.add(const DismissVolumeAlert('BTC'))).called(1);
        }
      });
    });
  });
}
