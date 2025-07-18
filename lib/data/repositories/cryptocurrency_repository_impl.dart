import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/cryptocurrency_repository.dart';
import '../datasources/okx_api_service.dart';
import '../mappers/mappers.dart';
import '../../core/error/error_handling.dart';
import '../../core/network/network.dart';
import '../../core/utils/debouncer.dart';
import '../../core/constants/constants.dart';

class CryptocurrencyRepositoryImpl implements CryptocurrencyRepository {
  final OKXApiService _apiService;
  final NetworkErrorHandler _networkErrorHandler;
  final OfflineManager _offlineManager;

  // Stream controllers for real-time updates
  final _priceUpdatesController =
      StreamController<PriceUpdateEvent>.broadcast();
  final _volumeAlertsController = StreamController<VolumeAlert>.broadcast();
  final _connectionStatusController =
      StreamController<ConnectionStatus>.broadcast();

  // Internal state
  Timer? _updateTimer;
  List<Cryptocurrency> _currentCryptocurrencies = [];
  final Map<String, double> _previousVolumes = {};
  bool _isUpdating = false;

  // Debouncing and rate limiting for API calls
  late final AsyncDebouncer<void> _updateDebouncer;
  late final IntervalRateLimiter _apiRateLimiter;
  late final Debouncer _connectionStatusDebouncer;

  // Configuration
  static final Duration _updateInterval = AppConstants.defaultUpdateInterval;
  static final Duration _debounceDuration = AppConstants.fastAnimationDuration;
  static const Duration _rateLimitInterval = Duration(milliseconds: 1000);
  static final Duration _statusUpdateDebounce =
      AppConstants.fastAnimationDuration;
  static const double _volumeSpikeThreshold =
      AppConstants.volumeSpikeThreshold / 100; // Convert percentage to decimal

  CryptocurrencyRepositoryImpl(
    this._apiService,
    this._networkErrorHandler,
    this._offlineManager,
  ) {
    // Initialize debouncing utilities
    _updateDebouncer = AsyncDebouncer<void>(delay: _debounceDuration);
    _apiRateLimiter = IntervalRateLimiter(minInterval: _rateLimitInterval);
    _connectionStatusDebouncer = Debouncer(delay: _statusUpdateDebounce);
  }

  @override
  bool get isUpdating => _isUpdating;

  @override
  Future<List<Cryptocurrency>> getInitialCryptocurrencies() async {
    _updateConnectionStatus(true, 'Fetching initial data...');

    try {
      // Use network error handler for enhanced error handling and retry logic
      final result = await _networkErrorHandler.executeWithEnhancedHandling(
        () async {
          // Fetch instruments and tickers for supported cryptocurrencies
          final instrumentsResponse = await _apiService.getInstruments();
          final tickersResponse = await _apiService.getSupportedCryptoTickers();

          // Map API data to domain entities
          final allCryptocurrencies = CryptocurrencyMapper.fromOKXDataList(
            instrumentsResponse.data,
            tickersResponse.data,
          );

          // Filter to get only the required 10 cryptocurrencies
          final requiredCryptocurrencies =
              CryptocurrencyMapper.filterRequiredCryptocurrencies(
                allCryptocurrencies,
              );

          if (requiredCryptocurrencies.isEmpty) {
            throw const DataFailure(
              message: 'No required cryptocurrencies found',
              details:
                  'API response did not contain the required cryptocurrency symbols',
            );
          }

          return requiredCryptocurrencies;
        },
        config: NetworkRetryConfig.critical(),
        onEvent: (event) {
          // Update connection status based on network events
          if (event is NetworkOperationAttempting) {
            _updateConnectionStatus(
              true,
              'Fetching data... (attempt ${event.attempt})',
            );
          } else if (event is NetworkOperationRetrying) {
            _updateConnectionStatus(
              true,
              'Retrying in ${event.delay.inSeconds}s...',
            );
          } else if (event is NetworkOperationSkippedOffline) {
            _updateConnectionStatus(false, 'Offline - operation skipped');
          }
        },
      );

      if (result.isSuccess) {
        // Store current state for real-time updates
        _currentCryptocurrencies = result.data!;
        _initializePreviousVolumes();

        _updateConnectionStatus(true, 'Connected');
        return result.data!;
      } else {
        final failure = result.failure!;
        _updateConnectionStatus(false, 'Failed: ${failure.message}');
        throw failure;
      }
    } catch (e) {
      final failure = e is Failure
          ? e
          : e is Exception
          ? ErrorHandler.handleException(e)
          : UnknownFailure(
              message: 'Unexpected error occurred',
              details: e.toString(),
            );
      _updateConnectionStatus(false, 'Failed: ${failure.message}');
      throw failure;
    }
  }

  @override
  Stream<PriceUpdateEvent> getPriceUpdates() {
    return _priceUpdatesController.stream;
  }

  @override
  Stream<VolumeAlert> getVolumeAlerts() {
    return _volumeAlertsController.stream;
  }

  @override
  Stream<ConnectionStatus> getConnectionStatus() {
    return _connectionStatusController.stream;
  }

  @override
  Future<void> startRealTimeUpdates() async {
    if (_isUpdating) {
      return; // Already updating
    }

    _isUpdating = true;
    _updateConnectionStatus(true, 'Starting real-time updates...');

    // Start periodic updates
    _updateTimer = Timer.periodic(_updateInterval, (_) => _performUpdate());

    _updateConnectionStatus(true, 'Live');
  }

  @override
  Future<void> stopRealTimeUpdates() async {
    if (!_isUpdating) {
      return; // Already stopped
    }

    _isUpdating = false;
    _updateTimer?.cancel();
    _updateTimer = null;

    _updateConnectionStatus(false, 'Stopped');
  }

  Future<void> _performUpdate() async {
    if (!_isUpdating) return;

    // Use debounced update to prevent excessive API calls
    try {
      await _updateDebouncer.call(() async {
        if (!_isUpdating) return;
        await _performUpdateWithNetworkHandling();
      });
    } catch (e) {
      final failure = e is Failure
          ? e
          : e is Exception
          ? ErrorHandler.handleException(e)
          : UnknownFailure(message: 'Update failed', details: e.toString());
      _updateConnectionStatus(false, 'Update failed: ${failure.message}');

      // Check if we should go offline
      if (_networkErrorHandler.shouldGoOffline(failure)) {
        _updateConnectionStatus(
          false,
          'Offline - will retry when connection is restored',
        );
      } else {
        // Schedule reconnection attempt
        final retryDelay = _networkErrorHandler.getNetworkRetryDelay(
          failure,
          1,
        );
        Timer(retryDelay, () {
          if (_isUpdating) {
            _updateConnectionStatus(true, 'Reconnecting...');
          }
        });
      }
    }
  }

  Future<void> _performUpdateWithNetworkHandling() async {
    // Use network error handler for real-time updates with appropriate retry strategy
    final result = await _networkErrorHandler.executeWithEnhancedHandling(
      () => _fetchAndProcessUpdates(),
      config:
          NetworkRetryConfig.fast(), // Use fast config for real-time updates
      shouldRetry: (failure) {
        // Don't retry if we're offline or if updates were stopped
        if (!_isUpdating || _offlineManager.isOffline) {
          return false;
        }

        // Retry on network errors but not on data errors
        return failure is NetworkFailure ||
            failure is TimeoutFailure ||
            failure is ConnectionFailure ||
            (failure is ApiFailure && (failure.errorCode ?? 0) >= 500);
      },
      onEvent: (event) {
        // Update connection status based on network events
        if (event is NetworkOperationAttempting) {
          _updateConnectionStatus(
            true,
            'Updating... (attempt ${event.attempt})',
          );
        } else if (event is NetworkOperationRetrying) {
          _updateConnectionStatus(
            true,
            'Retrying in ${event.delay.inSeconds}s...',
          );
        } else if (event is NetworkOperationSkippedOffline) {
          _updateConnectionStatus(false, 'Offline - updates paused');
        } else if (event is NetworkOperationSucceeded) {
          _updateConnectionStatus(true, 'Live');
        }
      },
    );

    if (result.isSuccess) {
      // Success - connection is live
      if (_isUpdating) {
        _updateConnectionStatus(true, 'Live');
      }
    } else {
      // Handle failure
      final failure = result.failure!;
      throw failure;
    }
  }

  Future<void> _fetchAndProcessUpdates() async {
    if (_currentCryptocurrencies.isEmpty) {
      return; // No cryptocurrencies to update
    }

    // Get instrument IDs for the required cryptocurrencies
    final instrumentIds = _currentCryptocurrencies
        .map((crypto) => '${crypto.symbol}-USDT')
        .toList();

    // Use rate limiter to prevent excessive API calls
    await _apiRateLimiter.execute(() async {
      // Fetch updated ticker data
      final tickersResponse = await _apiService.getTickersForInstruments(
        instrumentIds,
      );

      await _processTickerUpdates(tickersResponse);
    });
  }

  Future<void> _processTickerUpdates(dynamic tickersResponse) async {
    // Process updates
    final updatedCryptocurrencies = <Cryptocurrency>[];

    for (final crypto in _currentCryptocurrencies) {
      final ticker = tickersResponse.data.firstWhere(
        (t) => t.instId == '${crypto.symbol}-USDT',
        orElse: () => throw Exception('Ticker not found for ${crypto.symbol}'),
      );

      // Update cryptocurrency with new ticker data
      final updatedCrypto = CryptocurrencyMapper.updateWithTicker(
        crypto,
        ticker,
      );
      updatedCryptocurrencies.add(updatedCrypto);

      // Check for price changes and emit events
      if (updatedCrypto.price != crypto.price) {
        _priceUpdatesController.add(
          PriceUpdateEvent(
            symbol: crypto.symbol,
            newPrice: updatedCrypto.price,
            priceChange: updatedCrypto.price - crypto.price,
            timestamp: updatedCrypto.lastUpdated,
          ),
        );
      }

      // Check for volume spikes
      _checkVolumeSpike(crypto, updatedCrypto);
    }

    // Update current state
    _currentCryptocurrencies = updatedCryptocurrencies;
  }

  void _checkVolumeSpike(Cryptocurrency previous, Cryptocurrency current) {
    final previousVolume =
        _previousVolumes[current.symbol] ?? current.volume24h;
    final currentVolume = current.volume24h;

    if (previousVolume > 0) {
      final volumeChange = (currentVolume - previousVolume) / previousVolume;

      if (volumeChange > _volumeSpikeThreshold) {
        // Volume spike detected
        final alert = VolumeAlert(
          symbol: current.symbol,
          currentVolume: currentVolume,
          previousVolume: previousVolume,
          spikePercentage: volumeChange,
        );

        _volumeAlertsController.add(alert);

        // Update the cryptocurrency to mark it has a volume spike
        final index = _currentCryptocurrencies.indexWhere(
          (crypto) => crypto.symbol == current.symbol,
        );
        if (index != -1) {
          _currentCryptocurrencies[index] = current.copyWith(
            hasVolumeSpike: true,
          );
        }
      }
    }

    // Update previous volume for next comparison
    _previousVolumes[current.symbol] = currentVolume;
  }

  void _initializePreviousVolumes() {
    _previousVolumes.clear();
    for (final crypto in _currentCryptocurrencies) {
      _previousVolumes[crypto.symbol] = crypto.volume24h;
    }
  }

  void _updateConnectionStatus(bool isConnected, String message) {
    // Debounce connection status updates to prevent excessive UI rebuilds
    _connectionStatusDebouncer.call(() {
      final status = ConnectionStatus(
        isConnected: isConnected,
        statusMessage: message,
        lastUpdate: DateTime.now(),
      );

      _connectionStatusController.add(status);
    });
  }

  /// Disposes of all resources and closes streams
  void dispose() {
    // Stop updates first to prevent new operations
    _isUpdating = false;

    // Cancel timer and any pending operations
    _updateTimer?.cancel();
    _updateTimer = null;

    // Dispose debouncing utilities and cancel any pending operations
    _updateDebouncer.dispose();
    _apiRateLimiter.dispose();
    _connectionStatusDebouncer.dispose();

    // Close stream controllers
    _priceUpdatesController.close();
    _volumeAlertsController.close();
    _connectionStatusController.close();

    // Clear internal state
    _currentCryptocurrencies.clear();
    _previousVolumes.clear();

    // Dispose API service
    try {
      _apiService.dispose();
    } catch (e) {
      // Log error but don't rethrow during disposal
      debugPrint('Error disposing API service: $e');
    }
  }
}
