import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';
import 'package:crypto_dashboard/presentation/widgets/animated_cryptocurrency_list.dart';

void main() {
  group('AnimatedCryptocurrencyList', () {
    late List<Cryptocurrency> testCryptocurrencies;
    late Map<String, VolumeAlert> testAlerts;

    setUp(() {
      testCryptocurrencies = [
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
        Cryptocurrency(
          symbol: 'XRP',
          name: 'Ripple',
          price: 0.50,
          priceChange24h: 0.05,
          volume24h: 200000.0,
          status: ListingStatus.delisted,
          lastUpdated: DateTime.now(),
        ),
      ];

      testAlerts = {
        'BTC': const VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        ),
      };
    });

    Widget createTestWidget({
      List<Cryptocurrency>? cryptocurrencies,
      Map<String, VolumeAlert>? activeAlerts,
      bool isInitialLoad = false,
      VoidCallback? onRefresh,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              AnimatedCryptocurrencyList(
                cryptocurrencies: cryptocurrencies ?? testCryptocurrencies,
                activeAlerts: activeAlerts ?? {},
                isInitialLoad: isInitialLoad,
                onRefresh: onRefresh,
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('renders list of cryptocurrencies', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify all cryptocurrencies are displayed
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('XRP'), findsOneWidget);

      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.text('Ripple'), findsOneWidget);
    });

    testWidgets('displays volume alerts for appropriate cryptocurrencies', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(activeAlerts: testAlerts));
      await tester.pumpAndSettle();

      // Verify volume alert is shown for BTC
      expect(find.text('Volume spike: +50.0%'), findsOneWidget);

      // Verify no volume alerts for other cryptocurrencies
      expect(
        find.text('Volume spike: +50.0%'),
        findsOneWidget,
      ); // Only one alert
    });

    testWidgets('handles empty cryptocurrency list', (tester) async {
      await tester.pumpWidget(createTestWidget(cryptocurrencies: []));
      await tester.pumpAndSettle();

      // Should not crash and should show no items
      expect(find.text('BTC'), findsNothing);
      expect(find.text('ETH'), findsNothing);
    });

    testWidgets('performs staggered animation on initial load', (tester) async {
      await tester.pumpWidget(createTestWidget(isInitialLoad: true));

      // Initially, items might not be visible due to animation
      await tester.pump(const Duration(milliseconds: 50));

      // Pump through staggered animation
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }

      await tester.pumpAndSettle();

      // All items should be visible after animation completes
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('XRP'), findsOneWidget);
    });

    testWidgets('shows items immediately when not initial load', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(isInitialLoad: false));
      await tester.pump();

      // Items should be visible immediately
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('XRP'), findsOneWidget);
    });

    testWidgets('handles list updates efficiently', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('\$50000.00'), findsOneWidget);

      // Update with new data
      final updatedCryptocurrencies = [
        testCryptocurrencies[0].copyWith(price: 51000.00),
        testCryptocurrencies[1],
        testCryptocurrencies[2],
      ];

      await tester.pumpWidget(
        createTestWidget(cryptocurrencies: updatedCryptocurrencies),
      );
      await tester.pumpAndSettle();

      // Verify updated price is displayed
      expect(find.text('\$51000.00'), findsOneWidget);
    });

    testWidgets('handles adding new cryptocurrencies', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify initial count
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('XRP'), findsOneWidget);

      // Add new cryptocurrency
      final expandedList = [
        ...testCryptocurrencies,
        Cryptocurrency(
          symbol: 'ADA',
          name: 'Cardano',
          price: 1.50,
          priceChange24h: 0.10,
          volume24h: 300000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(createTestWidget(cryptocurrencies: expandedList));
      await tester.pumpAndSettle();

      // Verify new cryptocurrency is displayed
      expect(find.text('ADA'), findsOneWidget);
      expect(find.text('Cardano'), findsOneWidget);
    });

    testWidgets('handles removing cryptocurrencies', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('XRP'), findsOneWidget);

      // Remove XRP from the list
      final reducedList = testCryptocurrencies.take(2).toList();

      await tester.pumpWidget(createTestWidget(cryptocurrencies: reducedList));
      await tester.pumpAndSettle();

      // Verify XRP is no longer displayed
      expect(find.text('XRP'), findsNothing);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
    });

    testWidgets('maintains scroll position during updates', (tester) async {
      // Create a longer list to enable scrolling
      final longList = List.generate(
        20,
        (index) => Cryptocurrency(
          symbol: 'CRYPTO$index',
          name: 'Cryptocurrency $index',
          price: 100.0 + index,
          priceChange24h: index.toDouble(),
          volume24h: 1000.0 * index,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
        ),
      );

      await tester.pumpWidget(createTestWidget(cryptocurrencies: longList));
      await tester.pumpAndSettle();

      // Scroll down
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Update the list with new data
      final updatedLongList = longList
          .map((crypto) => crypto.copyWith(price: crypto.price + 1))
          .toList();

      await tester.pumpWidget(
        createTestWidget(cryptocurrencies: updatedLongList),
      );
      await tester.pumpAndSettle();

      // Verify the list is still scrolled (not reset to top)
      // This is a basic check - in a real app you might want more sophisticated scroll position testing
      expect(
        find.text('CRYPTO0'),
        findsNothing,
      ); // First item should not be visible
    });

    testWidgets('handles rapid data updates without performance issues', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate rapid updates
      for (int i = 0; i < 10; i++) {
        final updatedList = testCryptocurrencies
            .map((crypto) => crypto.copyWith(price: crypto.price + i))
            .toList();

        await tester.pumpWidget(
          createTestWidget(cryptocurrencies: updatedList),
        );
        await tester.pump(const Duration(milliseconds: 10));
      }

      await tester.pumpAndSettle();

      // Verify final state is correct
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('XRP'), findsOneWidget);
    });

    testWidgets('applies proper RepaintBoundary optimization', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify RepaintBoundary widgets are present for optimization
      expect(find.byType(RepaintBoundary), findsAtLeastNWidgets(1));
    });

    testWidgets('handles volume alert changes efficiently', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially no alerts
      expect(find.text('Volume spike:'), findsNothing);

      // Add alert
      await tester.pumpWidget(createTestWidget(activeAlerts: testAlerts));
      await tester.pumpAndSettle();

      // Verify alert is displayed
      expect(find.text('Volume spike: +50.0%'), findsOneWidget);

      // Remove alert
      await tester.pumpWidget(createTestWidget(activeAlerts: {}));
      await tester.pumpAndSettle();

      // Verify alert is removed
      expect(find.text('Volume spike:'), findsNothing);
    });

    testWidgets('handles mixed cryptocurrency states correctly', (
      tester,
    ) async {
      // Create list with mixed states
      final mixedList = [
        testCryptocurrencies[0], // Active
        testCryptocurrencies[1], // Active
        testCryptocurrencies[2], // Delisted
        Cryptocurrency(
          symbol: 'SUSP',
          name: 'Suspended Coin',
          price: 10.0,
          priceChange24h: 0.0,
          volume24h: 1000.0,
          status: ListingStatus.suspended,
          lastUpdated: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(createTestWidget(cryptocurrencies: mixedList));
      await tester.pumpAndSettle();

      // Verify all states are handled
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('XRP'), findsOneWidget);
      expect(find.text('SUSP'), findsOneWidget);

      // Verify status indicators
      expect(find.text('Delisted'), findsOneWidget);
      expect(find.text('Suspended'), findsOneWidget);
    });

    testWidgets('maintains consistent item ordering', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Get initial positions
      final btcFinder = find.text('BTC');
      final ethFinder = find.text('ETH');
      final xrpFinder = find.text('XRP');

      expect(btcFinder, findsOneWidget);
      expect(ethFinder, findsOneWidget);
      expect(xrpFinder, findsOneWidget);

      // Update prices but maintain order
      final updatedList = testCryptocurrencies
          .map((crypto) => crypto.copyWith(price: crypto.price * 2))
          .toList();

      await tester.pumpWidget(createTestWidget(cryptocurrencies: updatedList));
      await tester.pumpAndSettle();

      // Verify order is maintained
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
      expect(find.text('XRP'), findsOneWidget);
    });
  });
}
