import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';
import 'package:crypto_dashboard/presentation/widgets/animated_cryptocurrency_card.dart';
import 'package:crypto_dashboard/presentation/bloc/bloc.dart';

// Mock classes
class MockCryptocurrencyBloc extends Mock implements CryptocurrencyBloc {}

void main() {
  group('AnimatedCryptocurrencyCard', () {
    late MockCryptocurrencyBloc mockBloc;
    late Cryptocurrency testCrypto;
    late VolumeAlert testAlert;

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

      // Register fallback values for mocktail
      registerFallbackValue(const DismissVolumeAlert('BTC'));
    });

    Widget createTestWidget({
      Cryptocurrency? crypto,
      VolumeAlert? alert,
      Duration? animationDelay,
    }) {
      return MaterialApp(
        home: BlocProvider<CryptocurrencyBloc>(
          create: (_) => mockBloc,
          child: Scaffold(
            body: AnimatedCryptocurrencyCard(
              cryptocurrency: crypto ?? testCrypto,
              volumeAlert: alert,
              animationDelay: animationDelay ?? Duration.zero,
            ),
          ),
        ),
      );
    }

    testWidgets('renders cryptocurrency card with basic information', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Verify basic cryptocurrency information is displayed
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('\$50000.00'), findsOneWidget);
      expect(find.text('+\$1500.50'), findsOneWidget);
    });

    testWidgets('displays active status correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Should not show any status badge for active cryptocurrencies
      expect(find.text('Delisted'), findsNothing);
      expect(find.text('Suspended'), findsNothing);
    });

    testWidgets('displays delisted status with proper styling', (tester) async {
      final delistedCrypto = testCrypto.copyWith(
        status: ListingStatus.delisted,
      );

      await tester.pumpWidget(createTestWidget(crypto: delistedCrypto));

      // Verify delisted status is shown
      expect(find.text('Delisted'), findsOneWidget);

      // Verify the status badge has proper styling
      final statusContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Delisted'),
              matching: find.byType(Container),
            )
            .first,
      );

      expect(statusContainer.decoration, isA<BoxDecoration>());
    });

    testWidgets('displays suspended status with proper styling', (
      tester,
    ) async {
      final suspendedCrypto = testCrypto.copyWith(
        status: ListingStatus.suspended,
      );

      await tester.pumpWidget(createTestWidget(crypto: suspendedCrypto));

      // Verify suspended status is shown
      expect(find.text('Suspended'), findsOneWidget);
    });

    testWidgets('shows volume alert when provided', (tester) async {
      await tester.pumpWidget(createTestWidget(alert: testAlert));

      // Wait for animations to complete
      await tester.pumpAndSettle();

      // Verify volume alert is displayed
      expect(find.text('Volume spike: +50.0%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('hides volume alert when not provided', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify no volume alert is displayed
      expect(find.text('Volume spike:'), findsNothing);
      expect(find.byIcon(Icons.trending_up), findsNothing);
    });

    testWidgets('handles volume alert dismissal', (tester) async {
      await tester.pumpWidget(createTestWidget(alert: testAlert));
      await tester.pumpAndSettle();

      // Find and tap the close button
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      await tester.tap(closeButton);
      await tester.pump();

      // Verify the dismiss event was added to the bloc
      verify(() => mockBloc.add(const DismissVolumeAlert('BTC'))).called(1);
    });

    testWidgets('animates card updates when cryptocurrency data changes', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Update with new price
      final updatedCrypto = testCrypto.copyWith(price: 51000.00);
      await tester.pumpWidget(createTestWidget(crypto: updatedCrypto));

      // Pump a few frames to see animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify new price is eventually displayed
      await tester.pumpAndSettle();
      expect(find.text('\$51000.00'), findsOneWidget);
    });

    testWidgets('applies proper styling for different price changes', (
      tester,
    ) async {
      // Test positive price change
      await tester.pumpWidget(createTestWidget());
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);

      // Test negative price change
      final negativeCrypto = testCrypto.copyWith(priceChange24h: -1500.50);
      await tester.pumpWidget(createTestWidget(crypto: negativeCrypto));

      expect(find.text('\$-1500.50'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('handles animation delays properly', (tester) async {
      const delay = Duration(milliseconds: 500);

      await tester.pumpWidget(
        createTestWidget(alert: testAlert, animationDelay: delay),
      );

      // Initially, alert should not be visible
      expect(find.text('Volume spike: +50.0%'), findsNothing);

      // Wait for the delay
      await tester.pump(delay);
      await tester.pumpAndSettle();

      // Now alert should be visible
      expect(find.text('Volume spike: +50.0%'), findsOneWidget);
    });

    testWidgets('shows shimmer effect for significant updates', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Update with significant price change (>5%)
      final significantUpdate = testCrypto.copyWith(
        price: 53000.00,
      ); // 6% increase
      await tester.pumpWidget(createTestWidget(crypto: significantUpdate));

      // Pump animation frames
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      // Verify the card is still there (shimmer effect is internal)
      expect(find.byType(AnimatedCryptocurrencyCard), findsOneWidget);
    });

    testWidgets('handles rapid data updates efficiently', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate rapid price updates
      for (double price = 50000; price <= 50010; price += 1) {
        final updatedCrypto = testCrypto.copyWith(price: price);
        await tester.pumpWidget(createTestWidget(crypto: updatedCrypto));
        await tester.pump(const Duration(milliseconds: 10));
      }

      await tester.pumpAndSettle();

      // Verify final price is displayed
      expect(find.text('\$50010.00'), findsOneWidget);
    });

    testWidgets('maintains card structure across different states', (
      tester,
    ) async {
      // Test with active cryptocurrency
      await tester.pumpWidget(createTestWidget());
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Column), findsAtLeastNWidgets(1));

      // Test with delisted cryptocurrency
      final delistedCrypto = testCrypto.copyWith(
        status: ListingStatus.delisted,
      );
      await tester.pumpWidget(createTestWidget(crypto: delistedCrypto));
      expect(find.byType(Card), findsOneWidget);

      // Test with volume alert
      await tester.pumpWidget(createTestWidget(alert: testAlert));
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('applies proper opacity for delisted cryptocurrencies', (
      tester,
    ) async {
      final delistedCrypto = testCrypto.copyWith(
        status: ListingStatus.delisted,
      );

      await tester.pumpWidget(createTestWidget(crypto: delistedCrypto));
      await tester.pumpAndSettle();

      // Find the symbol text widget
      final symbolText = tester.widget<Text>(find.text('BTC'));
      final textStyle = symbolText.style;

      // Verify that delisted cryptocurrencies have reduced opacity
      expect(textStyle?.color?.alpha, lessThan(255));
    });

    testWidgets('handles volume alert animation lifecycle', (tester) async {
      // Start without alert
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      expect(find.text('Volume spike:'), findsNothing);

      // Add alert
      await tester.pumpWidget(createTestWidget(alert: testAlert));

      // Pump animation frames
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify alert is now visible
      expect(find.text('Volume spike: +50.0%'), findsOneWidget);

      // Remove alert
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify alert is gone
      expect(find.text('Volume spike: +50.0%'), findsNothing);
    });
  });
}
