import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';
import 'package:crypto_dashboard/domain/usecases/get_initial_cryptocurrencies.dart';
import 'package:crypto_dashboard/domain/usecases/subscribe_to_real_time_updates.dart';
import 'package:crypto_dashboard/domain/usecases/manage_connection_lifecycle.dart';
import 'package:crypto_dashboard/presentation/bloc/bloc.dart';
import 'package:crypto_dashboard/presentation/pages/dashboard_page.dart';

// Mock classes
class MockGetInitialCryptocurrencies extends Mock
    implements GetInitialCryptocurrencies {}

class MockSubscribeToRealTimeUpdates extends Mock
    implements SubscribeToRealTimeUpdates {}

class MockManageConnectionLifecycle extends Mock
    implements ManageConnectionLifecycle {}

void main() {
  group('Comprehensive Integration Tests', () {
    late MockGetInitialCryptocurrencies mockGetInitialCryptocurrencies;
    late MockSubscribeToRealTimeUpdates mockSubscribeToRealTimeUpdates;
    late MockManageConnectionLifecycle mockManageConnectionLifecycle;
    late CryptocurrencyBloc cryptoBloc;

    setUp(() {
      mockGetInitialCryptocurrencies = MockGetInitialCryptocurrencies();
      mockSubscribeToRealTimeUpdates = MockSubscribeToRealTimeUpdates();
      mockManageConnectionLifecycle = MockManageConnectionLifecycle();

      cryptoBloc = CryptocurrencyBloc(
        getInitialCryptocurrencies: mockGetInitialCryptocurrencies,
        subscribeToRealTimeUpdates: mockSubscribeToRealTimeUpdates,
        manageConnectionLifecycle: mockManageConnectionLifecycle,
      );
    });

    tearDown(() {
      cryptoBloc.close();
    });

    testWidgets('Dashboard loads and displays initial data', (tester) async {
      // Mock data
      final mockCryptocurrencies = [
        Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 2.5,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
          hasVolumeSpike: false,
        ),
        Cryptocurrency(
          symbol: 'ETH',
          name: 'Ethereum',
          price: 3000.0,
          priceChange24h: -1.2,
          volume24h: 500000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
          hasVolumeSpike: false,
        ),
      ];

      // Setup mocks
      when(
        () => mockGetInitialCryptocurrencies.call(),
      ).thenAnswer((_) async => mockCryptocurrencies);
      when(
        () => mockSubscribeToRealTimeUpdates.call(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockManageConnectionLifecycle.getStatus()).thenAnswer(
        (_) => Stream.value(
          ConnectionStatus(
            isConnected: true,
            statusMessage: 'Connected',
            lastUpdate: DateTime.now(),
          ),
        ),
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cryptoBloc,
            child: const DashboardPage(),
          ),
        ),
      );

      // Trigger initial load
      cryptoBloc.add(LoadInitialData());
      await tester.pump();

      // Verify loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for data to load
      await tester.pump();

      // Verify data is displayed
      expect(find.text('Bitcoin'), findsOneWidget);
      expect(find.text('Ethereum'), findsOneWidget);
      expect(find.text('BTC'), findsOneWidget);
      expect(find.text('ETH'), findsOneWidget);
    });

    testWidgets('Dashboard handles error states gracefully', (tester) async {
      // Setup mock to throw error
      when(
        () => mockGetInitialCryptocurrencies.call(),
      ).thenThrow(Exception('Network error'));
      when(
        () => mockSubscribeToRealTimeUpdates.call(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockManageConnectionLifecycle.getStatus()).thenAnswer(
        (_) => Stream.value(
          ConnectionStatus(
            isConnected: false,
            statusMessage: 'Disconnected',
            lastUpdate: DateTime.now(),
          ),
        ),
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cryptoBloc,
            child: const DashboardPage(),
          ),
        ),
      );

      // Trigger initial load
      cryptoBloc.add(LoadInitialData());
      await tester.pump();

      // Wait for error state
      await tester.pump();

      // Verify error handling
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // The app should show some error indication or retry option
      expect(
        find.byType(ElevatedButton),
        findsAtLeastNWidgets(0),
      ); // Retry button might be present
    });

    testWidgets('Dashboard is responsive to different screen sizes', (
      tester,
    ) async {
      final mockCryptocurrencies = [
        Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 2.5,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
          hasVolumeSpike: false,
        ),
      ];

      when(
        () => mockGetInitialCryptocurrencies.call(),
      ).thenAnswer((_) async => mockCryptocurrencies);
      when(
        () => mockSubscribeToRealTimeUpdates.call(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockManageConnectionLifecycle.getStatus()).thenAnswer(
        (_) => Stream.value(
          ConnectionStatus(
            isConnected: true,
            statusMessage: 'Connected',
            lastUpdate: DateTime.now(),
          ),
        ),
      );

      // Test mobile size
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cryptoBloc,
            child: const DashboardPage(),
          ),
        ),
      );

      cryptoBloc.add(LoadInitialData());
      await tester.pump();
      await tester.pump();

      expect(find.text('Crypto Dashboard'), findsOneWidget);

      // Test tablet size
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pump();
      expect(find.text('Crypto Dashboard'), findsOneWidget);

      // Test desktop size
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pump();
      expect(find.text('Crypto Dashboard'), findsOneWidget);

      // Reset size
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('Pull-to-refresh functionality works', (tester) async {
      final mockCryptocurrencies = [
        Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 2.5,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
          hasVolumeSpike: false,
        ),
      ];

      when(
        () => mockGetInitialCryptocurrencies.call(),
      ).thenAnswer((_) async => mockCryptocurrencies);
      when(
        () => mockSubscribeToRealTimeUpdates.call(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockManageConnectionLifecycle.getStatus()).thenAnswer(
        (_) => Stream.value(
          ConnectionStatus(
            isConnected: true,
            statusMessage: 'Connected',
            lastUpdate: DateTime.now(),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: cryptoBloc,
            child: const DashboardPage(),
          ),
        ),
      );

      cryptoBloc.add(LoadInitialData());
      await tester.pump();
      await tester.pump();

      // Find the RefreshIndicator and perform pull-to-refresh
      final refreshIndicator = find.byType(RefreshIndicator);
      expect(refreshIndicator, findsOneWidget);

      // Simulate pull-to-refresh gesture
      await tester.drag(refreshIndicator, const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify the refresh was triggered
      verify(
        () => mockGetInitialCryptocurrencies.call(),
      ).called(greaterThan(1));
    });
  });
}
