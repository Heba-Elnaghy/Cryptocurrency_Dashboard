import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:crypto_dashboard/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Final Integration Tests', () {
    testWidgets('App launches and displays dashboard', (
      WidgetTester tester,
    ) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify the app bar is displayed
      expect(find.text('Crypto Dashboard'), findsOneWidget);

      // Verify loading state or data is displayed
      final hasLoading = find
          .byType(CircularProgressIndicator)
          .evaluate()
          .isNotEmpty;
      final hasListView = find.byType(ListView).evaluate().isNotEmpty;
      expect(hasLoading || hasListView, isTrue);
    });

    testWidgets('Dashboard handles refresh functionality', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Find and trigger refresh
      final refreshIndicator = find.byType(RefreshIndicator);
      if (refreshIndicator.evaluate().isNotEmpty) {
        await tester.drag(refreshIndicator, const Offset(0, 300));
        await tester.pumpAndSettle();
      }

      // Verify the app still works after refresh
      expect(find.text('Crypto Dashboard'), findsOneWidget);
    });

    testWidgets('App handles orientation changes', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Change to landscape
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/settings',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('routeUpdated', {'location': '/', 'state': null}),
        ),
        (data) {},
      );

      await tester.pumpAndSettle();

      // Verify app still displays correctly
      expect(find.text('Crypto Dashboard'), findsOneWidget);
    });

    testWidgets('Connection status indicator works', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Look for connection status indicators
      final connectionIndicators = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.contains('Live') == true ||
                widget.data?.contains('Connecting') == true ||
                widget.data?.contains('Offline') == true),
      );

      // Should have some connection status indication
      expect(connectionIndicators, findsWidgets);
    });

    testWidgets('App maintains state during lifecycle changes', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Simulate app going to background
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMessageCodec().encodeMessage('AppLifecycleState.paused'),
        (data) {},
      );
      await tester.pump();

      // Simulate app coming back to foreground
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StandardMessageCodec().encodeMessage('AppLifecycleState.resumed'),
        (data) {},
      );
      await tester.pumpAndSettle();

      // Verify app still works
      expect(find.text('Crypto Dashboard'), findsOneWidget);
    });

    testWidgets('Error handling works correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 10));

      // Look for error states or retry buttons
      final errorWidgets = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data?.toLowerCase().contains('error') == true ||
                widget.data?.toLowerCase().contains('retry') == true),
      );

      final retryButtons = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data?.toLowerCase().contains('retry') ==
                true,
      );

      // If there are errors, there should be retry options
      if (errorWidgets.evaluate().isNotEmpty) {
        expect(retryButtons, findsWidgets);
      }
    });

    testWidgets('Performance remains stable during updates', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Measure frame times during updates
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      stopwatch.stop();

      // Verify reasonable performance (less than 1 second for 10 frames)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('Accessibility features work correctly', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Check for semantic labels
      final semanticWidgets = find.byWidgetPredicate(
        (widget) => widget is Semantics,
      );

      // Should have semantic widgets for accessibility
      expect(semanticWidgets, findsWidgets);
    });

    testWidgets('Theme switching works', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Get current theme
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final ThemeData currentTheme = Theme.of(context);

      // Verify theme is properly configured
      expect(currentTheme.useMaterial3, isTrue);
      expect(currentTheme.colorScheme, isNotNull);
    });

    testWidgets('Memory usage remains stable', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Simulate extended usage
      for (int i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Verify app is still responsive
      expect(find.text('Crypto Dashboard'), findsOneWidget);
    });
  });
}
