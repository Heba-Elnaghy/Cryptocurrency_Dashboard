import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';
import 'package:crypto_dashboard/presentation/widgets/animated_connection_status.dart';

void main() {
  group('AnimatedConnectionStatus', () {
    final testTime = DateTime.now();

    testWidgets('displays connection status with proper animations', (
      tester,
    ) async {
      // Create a test connection status
      final connectionStatus = ConnectionStatus(
        isConnected: true,
        statusMessage: 'Live',
        lastUpdate: testTime,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(connectionStatus: connectionStatus),
          ),
        ),
      );

      // Verify the widget is displayed
      expect(find.text('Live'), findsOneWidget);
      expect(find.byType(AnimatedConnectionStatus), findsOneWidget);
    });

    testWidgets('shows connecting state with spinner animation', (
      tester,
    ) async {
      // Create a connecting status
      final connectionStatus = ConnectionStatus(
        isConnected: false,
        statusMessage: 'Connecting...',
        lastUpdate: testTime,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(connectionStatus: connectionStatus),
          ),
        ),
      );

      // Verify the connecting message is displayed
      expect(find.text('Connecting...'), findsOneWidget);

      // Pump frames to test animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // The widget should still be there after animation frames
      expect(find.text('Connecting...'), findsOneWidget);
    });

    testWidgets('animates status transitions smoothly', (tester) async {
      // Start with connecting status
      final connectingStatus = ConnectionStatus(
        isConnected: false,
        statusMessage: 'Connecting...',
        lastUpdate: testTime,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(connectionStatus: connectingStatus),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Connecting...'), findsOneWidget);

      // Change to live status
      final liveStatus = ConnectionStatus(
        isConnected: true,
        statusMessage: 'Live',
        lastUpdate: testTime.add(const Duration(seconds: 1)),
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
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // Verify final state
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('handles reconnecting status with proper animations', (
      tester,
    ) async {
      // Create a reconnecting status
      final connectionStatus = ConnectionStatus(
        isConnected: false,
        statusMessage: 'Reconnecting...',
        lastUpdate: testTime,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(connectionStatus: connectionStatus),
          ),
        ),
      );

      // Verify the reconnecting message is displayed
      expect(find.text('Reconnecting...'), findsOneWidget);

      // Test animation by pumping frames
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Should still show reconnecting status
      expect(find.text('Reconnecting...'), findsOneWidget);
    });

    testWidgets('displays error status correctly', (tester) async {
      // Create an error status
      final connectionStatus = ConnectionStatus(
        isConnected: false,
        statusMessage: 'Connection Failed',
        lastUpdate: testTime,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(connectionStatus: connectionStatus),
          ),
        ),
      );

      // Verify the error message is displayed
      expect(find.text('Connection Failed'), findsOneWidget);
    });

    testWidgets('shows enhanced spinner animation for connecting state', (
      tester,
    ) async {
      // Create a connecting status
      final connectionStatus = ConnectionStatus(
        isConnected: false,
        statusMessage: 'Connecting...',
        lastUpdate: testTime,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(connectionStatus: connectionStatus),
          ),
        ),
      );

      // Verify the connecting message is displayed
      expect(find.text('Connecting...'), findsOneWidget);

      // Test enhanced spinner animation by pumping multiple frames
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      // The widget should still be there after animation frames
      expect(find.text('Connecting...'), findsOneWidget);
    });

    testWidgets('shows live status with glow effect', (tester) async {
      // Create a live status
      final connectionStatus = ConnectionStatus(
        isConnected: true,
        statusMessage: 'Live',
        lastUpdate: testTime,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(connectionStatus: connectionStatus),
          ),
        ),
      );

      // Verify the live message is displayed
      expect(find.text('Live'), findsOneWidget);

      // Pump frames to ensure animations settle
      await tester.pumpAndSettle();

      // The widget should still be there after animations
      expect(find.text('Live'), findsOneWidget);
    });

    testWidgets('handles rapid status changes smoothly', (tester) async {
      // Start with connecting status
      final connectingStatus = ConnectionStatus(
        isConnected: false,
        statusMessage: 'Connecting...',
        lastUpdate: testTime,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(connectionStatus: connectingStatus),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Connecting...'), findsOneWidget);

      // Change to live status
      final liveStatus = ConnectionStatus(
        isConnected: true,
        statusMessage: 'Live',
        lastUpdate: testTime.add(const Duration(seconds: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(connectionStatus: liveStatus),
          ),
        ),
      );

      // Change to reconnecting status quickly
      final reconnectingStatus = ConnectionStatus(
        isConnected: false,
        statusMessage: 'Reconnecting...',
        lastUpdate: testTime.add(const Duration(seconds: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedConnectionStatus(
              connectionStatus: reconnectingStatus,
            ),
          ),
        ),
      );

      // Pump animation frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify final state
      expect(find.text('Reconnecting...'), findsOneWidget);
    });
  });
}
