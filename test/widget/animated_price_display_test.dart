import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/presentation/widgets/animated_price_display.dart';

void main() {
  group('AnimatedPriceDisplay', () {
    testWidgets('should display price and change correctly', (
      WidgetTester tester,
    ) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedPriceDisplay(price: 50000.00, priceChange: 1500.50),
          ),
        ),
      );

      // Verify price is displayed
      expect(find.text('\$50000.00'), findsOneWidget);
      expect(find.text('+\$1500.50'), findsOneWidget);

      // Verify positive change icon
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('should display negative price change correctly', (
      WidgetTester tester,
    ) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedPriceDisplay(price: 48000.00, priceChange: -2000.50),
          ),
        ),
      );

      // Verify price is displayed
      expect(find.text('\$48000.00'), findsOneWidget);
      expect(find.text('\$-2000.50'), findsOneWidget);

      // Verify negative change icon
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('should create widget without errors', (
      WidgetTester tester,
    ) async {
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedPriceDisplay(price: 50000.00, priceChange: 1500.50),
          ),
        ),
      );

      // Just verify the widget builds without errors
      expect(find.byType(AnimatedPriceDisplay), findsOneWidget);
    });
  });
}
