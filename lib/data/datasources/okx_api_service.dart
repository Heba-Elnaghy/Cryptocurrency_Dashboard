import '../models/models.dart';
import '../../core/network/network.dart';
import '../../core/error/error_handling.dart';
import '../../core/constants/constants.dart';

class OKXApiService {
  final NetworkClient _networkClient;
  final OfflineManager? _offlineManager;
  final OfflineDetector? _offlineDetector;

  OKXApiService({
    required NetworkInfo networkInfo,
    NetworkClient? networkClient,
    OfflineManager? offlineManager,
    OfflineDetector? offlineDetector,
  }) : _offlineManager = offlineManager,
       _offlineDetector = offlineDetector,
       _networkClient =
           networkClient ??
           NetworkClient(
             networkInfo,
             config: NetworkClientConfig.api,
             baseUrl: ApiEndpoints.baseUrl,
             headers: {
               'Content-Type': 'application/json',
               'Accept': 'application/json',
             },
             offlineManager: offlineManager,
             offlineDetector: offlineDetector,
           );

  /// Fetches the list of trading instruments from OKX API
  /// Returns instruments filtered for SPOT trading
  Future<OKXInstrumentResponse> getInstruments() async {
    try {
      final response = await _networkClient.get(
        ApiEndpoints.instruments,
        queryParameters: {
          ApiEndpoints.instTypeParam: ApiEndpoints.spotInstType,
        },
        config: NetworkClientConfig.api,
      );

      return OKXInstrumentResponse.fromJson(response.data);
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw ErrorHandler.handleException(e as Exception);
    }
  }

  /// Fetches ticker data for all SPOT instruments
  /// Returns current price and volume information
  Future<OKXTickerResponse> getTickers() async {
    try {
      final response = await _networkClient.get(
        ApiEndpoints.tickers,
        queryParameters: ApiEndpoints.getDefaultParams(),
        config: NetworkClientConfig.api,
      );

      return OKXTickerResponse.fromJson(response.data);
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw ErrorHandler.handleException(e as Exception);
    }
  }

  /// Fetches ticker data for specific instruments
  /// [instIds] - List of instrument IDs to fetch (e.g., ['BTC-USDT', 'ETH-USDT'])
  Future<OKXTickerResponse> getTickersForInstruments(
    List<String> instIds,
  ) async {
    if (instIds.isEmpty) {
      throw const DataFailure(
        message: 'Invalid request',
        details: 'Instrument IDs list cannot be empty',
      );
    }

    try {
      final response = await _networkClient.get(
        ApiEndpoints.tickers,
        queryParameters: {
          ApiEndpoints.instTypeParam: ApiEndpoints.spotInstType,
          ApiEndpoints.instIdParam: instIds.join(','),
        },
        config: NetworkClientConfig.realTime,
      );

      return OKXTickerResponse.fromJson(response.data);
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw ErrorHandler.handleException(e as Exception);
    }
  }

  /// Fetches ticker data for supported cryptocurrencies
  /// Returns ticker data for BTC, ETH, XRP, BNB, SOL, DOGE, TRX, ADA, HYPE, XLM
  Future<OKXTickerResponse> getSupportedCryptoTickers() async {
    try {
      final response = await _networkClient.get(
        ApiEndpoints.tickers,
        queryParameters: ApiEndpoints.getSupportedCryptosParams(),
        config: NetworkClientConfig.realTime,
      );

      return OKXTickerResponse.fromJson(response.data);
    } catch (e) {
      if (e is Failure) {
        rethrow;
      }
      throw ErrorHandler.handleException(e as Exception);
    }
  }

  /// Gets network connection information
  Future<NetworkConnectionInfo> getConnectionInfo() {
    return _networkClient.getConnectionInfo();
  }

  /// Checks if network is available
  Future<bool> get isNetworkAvailable => _networkClient.isNetworkAvailable;

  /// Stream of network client events for monitoring
  Stream<NetworkClientEvent> get networkEvents => _networkClient.events;

  /// Checks if the service is currently offline
  bool get isOffline => _offlineManager?.isOffline ?? false;

  /// Gets offline duration if currently offline
  Duration? get offlineDuration => _offlineManager?.getOfflineDuration();

  /// Gets offline message for display
  String get offlineMessage => _offlineManager?.getOfflineMessage() ?? '';

  /// Stream of offline state changes
  Stream<OfflineState>? get onOfflineStateChanged =>
      _offlineManager?.onOfflineStateChanged;

  /// Stream of offline detection events
  Stream<OfflineDetectionEvent>? get onOfflineDetectionEvents =>
      _offlineDetector?.events;

  /// Forces a connectivity check
  Future<void> checkConnectivity() async {
    await _offlineManager?.checkConnectivity();
    await _offlineDetector?.forceCheck();
  }

  /// Determines if cached data should be used
  bool get shouldUseCachedData =>
      _offlineManager?.shouldUseCachedData() ?? false;

  /// Gets retry strategy for current offline state
  OfflineRetryStrategy get retryStrategy =>
      _offlineManager?.getRetryStrategy() ?? OfflineRetryStrategy.immediate;

  /// Closes the HTTP client and cleans up resources
  void dispose() {
    _networkClient.dispose();
  }
}
