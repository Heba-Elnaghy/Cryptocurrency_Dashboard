import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/get_initial_cryptocurrencies.dart';
import '../../domain/usecases/manage_connection_lifecycle.dart';
import '../../domain/usecases/subscribe_to_real_time_updates.dart';
import '../../core/utils/debouncer.dart';
import '../../core/utils/performance_monitor.dart';
import 'cryptocurrency_event.dart';
import 'cryptocurrency_state.dart';

class CryptocurrencyBloc
    extends Bloc<CryptocurrencyEvent, CryptocurrencyState> {
  final GetInitialCryptocurrencies _getInitialCryptocurrencies;
  final SubscribeToRealTimeUpdates _subscribeToRealTimeUpdates;
  final ManageConnectionLifecycle _manageConnectionLifecycle;

  // Stream subscriptions for real-time updates
  StreamSubscription<CryptocurrencyUpdateEvent>? _realTimeUpdatesSubscription;
  StreamSubscription<ConnectionStatus>? _connectionStatusSubscription;

  // Debouncing utilities for efficient state updates
  late final Debouncer _stateUpdateDebouncer;
  late final Batcher<PriceUpdateEvent> _priceUpdateBatcher;
  late final Throttler _connectionStatusThrottler;

  CryptocurrencyBloc({
    required GetInitialCryptocurrencies getInitialCryptocurrencies,
    required SubscribeToRealTimeUpdates subscribeToRealTimeUpdates,
    required ManageConnectionLifecycle manageConnectionLifecycle,
  }) : _getInitialCryptocurrencies = getInitialCryptocurrencies,
       _subscribeToRealTimeUpdates = subscribeToRealTimeUpdates,
       _manageConnectionLifecycle = manageConnectionLifecycle,
       super(const CryptocurrencyInitial()) {
    // Initialize debouncing utilities for efficient state updates
    _stateUpdateDebouncer = Debouncer(delay: const Duration(milliseconds: 100));
    _priceUpdateBatcher = Batcher<PriceUpdateEvent>(
      delay: const Duration(milliseconds: 200),
      onBatch: _processBatchedPriceUpdates,
    );
    _connectionStatusThrottler = Throttler(
      duration: const Duration(milliseconds: 500),
    );

    // Register event handlers
    on<LoadInitialData>(_onLoadInitialData);
    on<StartRealTimeUpdates>(_onStartRealTimeUpdates);
    on<StopRealTimeUpdates>(_onStopRealTimeUpdates);
    on<RefreshData>(_onRefreshData);
    on<PriceUpdated>(_onPriceUpdated);
    on<VolumeAlertReceived>(_onVolumeAlertReceived);
    on<ConnectionStatusChanged>(_onConnectionStatusChanged);
    on<DismissVolumeAlert>(_onDismissVolumeAlert);
    on<AppLifecycleChanged>(_onAppLifecycleChanged);
  }

  /// Handles loading initial cryptocurrency data
  Future<void> _onLoadInitialData(
    LoadInitialData event,
    Emitter<CryptocurrencyState> emit,
  ) async {
    await PerformanceMonitor.measureAsync(
      'LoadInitialData',
      () async {
        try {
          emit(
            const CryptocurrencyLoading(message: 'Loading cryptocurrencies...'),
          );

          // Fetch initial data
          final cryptocurrencies = await _getInitialCryptocurrencies();

          if (cryptocurrencies.isEmpty) {
            emit(
              const CryptocurrencyError(
                message: 'No cryptocurrencies found',
                details: 'The required cryptocurrencies are not available',
              ),
            );
            return;
          }

          // Create initial loaded state
          final initialConnectionStatus = ConnectionStatus(
            isConnected: true,
            statusMessage: 'Connected',
            lastUpdate: DateTime.now(),
          );

          emit(
            CryptocurrencyLoaded(
              cryptocurrencies: cryptocurrencies,
              connectionStatus: initialConnectionStatus,
              lastUpdated: DateTime.now(),
            ),
          );

          // Automatically start real-time updates
          add(const StartRealTimeUpdates());
        } catch (e) {
          emit(
            CryptocurrencyError(
              message: 'Failed to load cryptocurrencies',
              details: e.toString(),
            ),
          );
        }
      },
      metadata: {
        'cryptoCount': state is CryptocurrencyLoaded
            ? (state as CryptocurrencyLoaded).cryptocurrencies.length
            : 0,
      },
    );
  }

  /// Handles starting real-time updates
  Future<void> _onStartRealTimeUpdates(
    StartRealTimeUpdates event,
    Emitter<CryptocurrencyState> emit,
  ) async {
    try {
      // Start the connection lifecycle management
      await _manageConnectionLifecycle.startUpdates();

      // Subscribe to real-time streams
      await _subscribeToStreams();

      // Update connection status if we have loaded data
      if (state is CryptocurrencyLoaded) {
        final currentState = state as CryptocurrencyLoaded;
        emit(
          currentState.copyWith(
            connectionStatus: ConnectionStatus(
              isConnected: true,
              statusMessage: 'Live',
              lastUpdate: DateTime.now(),
            ),
          ),
        );
      }
    } catch (e) {
      if (state is CryptocurrencyLoaded) {
        final currentState = state as CryptocurrencyLoaded;
        emit(
          currentState.copyWith(
            connectionStatus: ConnectionStatus(
              isConnected: false,
              statusMessage: 'Failed to start updates: ${e.toString()}',
              lastUpdate: DateTime.now(),
            ),
          ),
        );
      }
    }
  }

  /// Handles stopping real-time updates
  Future<void> _onStopRealTimeUpdates(
    StopRealTimeUpdates event,
    Emitter<CryptocurrencyState> emit,
  ) async {
    try {
      // Stop the connection lifecycle management
      await _manageConnectionLifecycle.stopUpdates();

      // Cancel stream subscriptions
      await _cancelSubscriptions();

      // Update connection status if we have loaded data
      if (state is CryptocurrencyLoaded) {
        final currentState = state as CryptocurrencyLoaded;
        emit(
          currentState.copyWith(
            connectionStatus: ConnectionStatus(
              isConnected: false,
              statusMessage: 'Stopped',
              lastUpdate: DateTime.now(),
            ),
          ),
        );
      }
    } catch (e) {
      // Handle error but don't emit error state for stop operation
      if (state is CryptocurrencyLoaded) {
        final currentState = state as CryptocurrencyLoaded;
        emit(
          currentState.copyWith(
            connectionStatus: ConnectionStatus(
              isConnected: false,
              statusMessage: 'Stopped with error: ${e.toString()}',
              lastUpdate: DateTime.now(),
            ),
          ),
        );
      }
    }
  }

  /// Handles manual data refresh (pull-to-refresh)
  Future<void> _onRefreshData(
    RefreshData event,
    Emitter<CryptocurrencyState> emit,
  ) async {
    if (state is! CryptocurrencyLoaded) return;

    final currentState = state as CryptocurrencyLoaded;

    try {
      // Emit refreshing state
      emit(
        CryptocurrencyRefreshing(
          cryptocurrencies: currentState.cryptocurrencies,
          connectionStatus: currentState.connectionStatus,
          activeAlerts: currentState.activeAlerts,
          lastUpdated: currentState.lastUpdated,
        ),
      );

      // Fetch fresh data
      final cryptocurrencies = await _getInitialCryptocurrencies();

      // Emit updated state
      emit(
        currentState.copyWith(
          cryptocurrencies: cryptocurrencies,
          isRefreshing: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      // Return to previous state on error
      emit(currentState.copyWith(isRefreshing: false));

      // Optionally show error as a temporary state or handle differently
      emit(
        CryptocurrencyError(
          message: 'Failed to refresh data',
          details: e.toString(),
          previousData: currentState.cryptocurrencies,
        ),
      );

      // Return to loaded state after a brief moment
      await Future.delayed(const Duration(seconds: 2));
      if (!isClosed) {
        emit(currentState);
      }
    }
  }

  /// Handles price update events with batching for efficiency
  void _onPriceUpdated(PriceUpdated event, Emitter<CryptocurrencyState> emit) {
    if (state is! CryptocurrencyLoaded) return;

    // Add to batch instead of processing immediately
    _priceUpdateBatcher.add(event.update);
  }

  /// Processes batched price updates for better performance
  void _processBatchedPriceUpdates(List<PriceUpdateEvent> updates) {
    if (state is! CryptocurrencyLoaded || updates.isEmpty) return;

    // Create a map of symbol to latest update for efficient processing
    final Map<String, PriceUpdateEvent> latestUpdates = {};
    for (final update in updates) {
      latestUpdates[update.symbol] = update;
    }

    // Use debounced state update to prevent excessive rebuilds
    _stateUpdateDebouncer.call(() {
      if (state is! CryptocurrencyLoaded) return;

      final currentState = state as CryptocurrencyLoaded;

      // Update cryptocurrencies efficiently using the optimized state methods
      final updateMap = <String, Cryptocurrency>{};

      for (final entry in latestUpdates.entries) {
        final symbol = entry.key;
        final update = entry.value;

        // Find the current cryptocurrency
        try {
          final currentCrypto = currentState.cryptocurrencies.firstWhere(
            (crypto) => crypto.symbol == symbol,
          );

          // Only update if there's a significant change to prevent unnecessary rebuilds
          final priceChange = (update.newPrice - currentCrypto.price).abs();
          if (priceChange > 0.001) {
            // Only update if price changed by more than 0.001
            updateMap[symbol] = currentCrypto.copyWith(
              price: update.newPrice,
              priceChange24h: update.priceChange,
              lastUpdated: update.timestamp,
            );
          }
        } catch (e) {
          // Cryptocurrency not found, skip this update
          continue;
        }
      }

      // Only emit new state if there are actual updates
      if (updateMap.isNotEmpty) {
        final newState = currentState.updateCryptocurrencies(updateMap);
        emit(newState);
      }
    });
  }

  /// Handles volume alert events
  void _onVolumeAlertReceived(
    VolumeAlertReceived event,
    Emitter<CryptocurrencyState> emit,
  ) {
    if (state is! CryptocurrencyLoaded) return;

    final currentState = state as CryptocurrencyLoaded;
    emit(currentState.addVolumeAlert(event.alert));
  }

  /// Handles connection status changes with throttling for efficiency
  void _onConnectionStatusChanged(
    ConnectionStatusChanged event,
    Emitter<CryptocurrencyState> emit,
  ) {
    if (state is! CryptocurrencyLoaded) return;

    // Use throttling to prevent excessive connection status updates
    _connectionStatusThrottler.call(() {
      if (state is! CryptocurrencyLoaded) return;

      final currentState = state as CryptocurrencyLoaded;

      // Only emit if the status actually changed
      if (currentState.connectionStatus != event.status) {
        emit(currentState.copyWith(connectionStatus: event.status));
      }
    });
  }

  /// Handles dismissing volume alerts
  void _onDismissVolumeAlert(
    DismissVolumeAlert event,
    Emitter<CryptocurrencyState> emit,
  ) {
    if (state is! CryptocurrencyLoaded) return;

    final currentState = state as CryptocurrencyLoaded;
    emit(currentState.removeVolumeAlert(event.symbol));
  }

  /// Handles app lifecycle changes for connection management
  Future<void> _onAppLifecycleChanged(
    AppLifecycleChanged event,
    Emitter<CryptocurrencyState> emit,
  ) async {
    if (event.isInForeground) {
      // App came to foreground - start updates if we have data
      if (state is CryptocurrencyLoaded) {
        add(const StartRealTimeUpdates());
      }
    } else {
      // App went to background - stop updates to save resources
      add(const StopRealTimeUpdates());
    }
  }

  /// Subscribes to real-time data streams
  Future<void> _subscribeToStreams() async {
    // Cancel existing subscriptions
    await _cancelSubscriptions();

    // Subscribe to the unified real-time updates stream
    _realTimeUpdatesSubscription = _subscribeToRealTimeUpdates().listen((
      event,
    ) {
      switch (event.type) {
        case CryptocurrencyUpdateEventType.priceUpdate:
          if (event.priceUpdate != null) {
            add(PriceUpdated(event.priceUpdate!));
          }
          break;
        case CryptocurrencyUpdateEventType.volumeAlert:
          if (event.volumeAlert != null) {
            add(VolumeAlertReceived(event.volumeAlert!));
          }
          break;
        case CryptocurrencyUpdateEventType.connectionStatus:
          if (event.connectionStatus != null) {
            add(ConnectionStatusChanged(event.connectionStatus!));
          }
          break;
      }
    });

    // Subscribe to connection status from lifecycle manager
    _connectionStatusSubscription = _manageConnectionLifecycle
        .getStatus()
        .listen((status) => add(ConnectionStatusChanged(status)));
  }

  /// Cancels all stream subscriptions
  Future<void> _cancelSubscriptions() async {
    await _realTimeUpdatesSubscription?.cancel();
    await _connectionStatusSubscription?.cancel();

    _realTimeUpdatesSubscription = null;
    _connectionStatusSubscription = null;
  }

  @override
  Future<void> close() async {
    // Clean up resources in proper order
    try {
      // 1. Stop real-time updates first to prevent new events
      if (_manageConnectionLifecycle.isUpdating) {
        await _manageConnectionLifecycle.stopUpdates();
      }

      // 2. Cancel all stream subscriptions
      await _cancelSubscriptions();

      // 3. Dispose debouncing utilities and cancel any pending operations
      _stateUpdateDebouncer.dispose();
      _priceUpdateBatcher.dispose();
      _connectionStatusThrottler.reset();

      // 4. Perform graceful shutdown of connection lifecycle
      await _manageConnectionLifecycle.gracefulShutdown();
    } catch (e) {
      // Log error but don't throw during cleanup to prevent resource leaks
      // In production, you would use proper logging
      // print('Warning: Error during BLoC cleanup: $e');
    }

    return super.close();
  }
}
