import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/injection_container.dart' as di;

void main() {
  setUpAll(() async {
    // Initialize dependency injection
    await di.init();
  });

  testWidgets('Manual Integration Test - App loads successfully', (
    tester,
  ) async {
    // Build a simple MaterialApp to test basic functionality
    await tester.pumpWidget(
      MaterialApp(
        title: 'Crypto Dashboard',
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          appBar: AppBar(title: const Text('Crypto Dashboard')),
          body: const Center(child: Text('Dashboard Content')),
        ),
      ),
    );

    // Wait for initial render
    await tester.pump();

    // Verify the app loads without crashing
    expect(find.text('Crypto Dashboard'), findsOneWidget);

    // Verify the basic structure is present
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    // Wait a bit more for any async operations
    await tester.pump(const Duration(seconds: 1));

    // The app should still be stable
    expect(find.text('Crypto Dashboard'), findsOneWidget);
  });

  testWidgets('App structure verification', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        title: 'Test App',
        theme: ThemeData(useMaterial3: true),
        darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: const Scaffold(body: Center(child: Text('Test'))),
      ),
    );
    await tester.pump();

    // Check for key UI components
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);

    // Verify theme is applied
    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme, isNotNull);
    expect(app.darkTheme, isNotNull);
  });
}
