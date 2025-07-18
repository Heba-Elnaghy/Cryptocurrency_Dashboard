import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:crypto_dashboard/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Integration Tests', () {
    testWidgets('App loads and displays cryptocurrency dashboard', (
      tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify the app bar is displayed
      expect(find.text('Crypto Dashboard'), findsOneWidget);

      // Verify connection status indicator is present
      expect(find.byType(Icon), findsAtLeastNWidgets(1));

      // Wait for initial data load
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Verify cryptocurrency cards are displayed
      expect(find.byType(Card), findsAtLeastNWidgets(1));

      // Test pull-to-refresh functionality
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 300));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify the app is still responsive
      expect(find.text('Crypto Dashboard'), findsOneWidget);
    });

    testWidgets('App handles network errors gracefully', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Wait for potential error states
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // The app should either show data or a proper error state
      // but should not crash
      expect(find.text('Crypto Dashboard'), findsOneWidget);
    });

    testWidgets('App maintains responsive layout', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Test different screen sizes by changing the window size
      await tester.binding.setSurfaceSize(const Size(400, 800)); // Mobile
      await tester.pumpAndSettle();
      expect(find.text('Crypto Dashboard'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(800, 600)); // Tablet
      await tester.pumpAndSettle();
      expect(find.text('Crypto Dashboard'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(1200, 800)); // Desktop
      await tester.pumpAndSettle();
      expect(find.text('Crypto Dashboard'), findsOneWidget);

      // Reset to default size
      await tester.binding.setSurfaceSize(null);
    });
  });
}
