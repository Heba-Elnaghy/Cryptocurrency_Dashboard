/// API endpoints configuration for the crypto dashboard
class ApiEndpoints {
  // Private constructor to prevent instantiation
  ApiEndpoints._();

  /// Base URL for OKX API
  static const String baseUrl = 'https://www.okx.com';

  /// API version prefix
  static const String apiVersion = '/api/v5';

  // ==================== Public Market Data ====================

  /// Get trading instruments
  /// Query params: instType (required)
  static const String instruments = '$apiVersion/public/instruments';

  /// Get ticker information
  /// Query params: instType (required), instId (optional)
  static const String tickers = '$apiVersion/market/tickers';

  /// Get order book data
  /// Query params: instId (required), sz (optional)
  static const String orderBook = '$apiVersion/market/books';

  /// Get candlestick data
  /// Query params: instId (required), bar (optional), after (optional), before (optional), limit (optional)
  static const String candlesticks = '$apiVersion/market/candles';

  /// Get recent trades
  /// Query params: instId (required), limit (optional)
  static const String trades = '$apiVersion/market/trades';

  /// Get 24hr ticker statistics
  /// Query params: instType (required), uly (optional), instFamily (optional)
  static const String ticker24hr = '$apiVersion/market/ticker';

  // ==================== System Status ====================

  /// Get system status
  static const String systemStatus = '$apiVersion/system/status';

  /// Get system time
  static const String systemTime = '$apiVersion/public/time';

  // ==================== Instrument Types ====================

  /// Spot trading instrument type
  static const String spotInstType = 'SPOT';

  /// Futures trading instrument type
  static const String futuresInstType = 'FUTURES';

  /// Perpetual swap instrument type
  static const String swapInstType = 'SWAP';

  /// Options instrument type
  static const String optionInstType = 'OPTION';

  // ==================== Common Query Parameters ====================

  /// Query parameter keys
  static const String instTypeParam = 'instType';
  static const String instIdParam = 'instId';
  static const String limitParam = 'limit';
  static const String afterParam = 'after';
  static const String beforeParam = 'before';
  static const String sizeParam = 'sz';
  static const String barParam = 'bar';

  // ==================== Default Values ====================

  /// Default limit for API requests
  static const int defaultLimit = 100;

  /// Maximum limit for API requests
  static const int maxLimit = 500;

  /// Default order book depth
  static const int defaultOrderBookDepth = 20;

  // ==================== Rate Limits ====================

  /// Rate limit for public endpoints (requests per second)
  static const int publicRateLimit = 20;

  /// Rate limit for market data endpoints (requests per second)
  static const int marketDataRateLimit = 40;

  // ==================== Supported Cryptocurrencies ====================

  /// List of supported cryptocurrency symbols for the dashboard
  static const List<String> supportedCryptos = [
    'BTC',
    'ETH',
    'XRP',
    'BNB',
    'SOL',
    'DOGE',
    'TRX', // TRON
    'ADA',
    'HYPE',
    'XLM',
  ];

  /// Convert crypto symbols to OKX instrument IDs (with USDT pairs)
  static List<String> getCryptoInstrumentIds() {
    return supportedCryptos.map((symbol) => '$symbol-USDT').toList();
  }

  /// Get instrument ID for a specific crypto symbol
  static String getInstrumentId(
    String symbol, {
    String quoteCurrency = 'USDT',
  }) {
    return '$symbol-$quoteCurrency';
  }

  // ==================== Helper Methods ====================

  /// Build full URL for an endpoint
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Build instruments endpoint with query parameters
  static String buildInstrumentsUrl({
    required String instType,
    String? uly,
    String? instFamily,
    String? instId,
  }) {
    final params = <String, String>{instTypeParam: instType};

    if (uly != null) params['uly'] = uly;
    if (instFamily != null) params['instFamily'] = instFamily;
    if (instId != null) params[instIdParam] = instId;

    return _buildUrlWithParams(instruments, params);
  }

  /// Build tickers endpoint with query parameters
  static String buildTickersUrl({
    required String instType,
    String? instId,
    String? uly,
    String? instFamily,
  }) {
    final params = <String, String>{instTypeParam: instType};

    if (instId != null) params[instIdParam] = instId;
    if (uly != null) params['uly'] = uly;
    if (instFamily != null) params['instFamily'] = instFamily;

    return _buildUrlWithParams(tickers, params);
  }

  /// Build order book endpoint with query parameters
  static String buildOrderBookUrl({required String instId, int? size}) {
    final params = <String, String>{instIdParam: instId};

    if (size != null) params[sizeParam] = size.toString();

    return _buildUrlWithParams(orderBook, params);
  }

  /// Build candlesticks endpoint with query parameters
  static String buildCandlesticksUrl({
    required String instId,
    String? bar,
    String? after,
    String? before,
    int? limit,
  }) {
    final params = <String, String>{instIdParam: instId};

    if (bar != null) params[barParam] = bar;
    if (after != null) params[afterParam] = after;
    if (before != null) params[beforeParam] = before;
    if (limit != null) params[limitParam] = limit.toString();

    return _buildUrlWithParams(candlesticks, params);
  }

  /// Build trades endpoint with query parameters
  static String buildTradesUrl({required String instId, int? limit}) {
    final params = <String, String>{instIdParam: instId};

    if (limit != null) params[limitParam] = limit.toString();

    return _buildUrlWithParams(trades, params);
  }

  // ==================== Private Helper Methods ====================

  /// Build URL with query parameters
  static String _buildUrlWithParams(
    String endpoint,
    Map<String, String> params,
  ) {
    if (params.isEmpty) return endpoint;

    final queryString = params.entries
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
        .join('&');

    return '$endpoint?$queryString';
  }

  // ==================== Validation Methods ====================

  /// Validate instrument type
  static bool isValidInstType(String instType) {
    return [
      spotInstType,
      futuresInstType,
      swapInstType,
      optionInstType,
    ].contains(instType);
  }

  /// Validate limit parameter
  static bool isValidLimit(int limit) {
    return limit > 0 && limit <= maxLimit;
  }

  /// Validate if crypto symbol is supported
  static bool isSupportedCrypto(String symbol) {
    return supportedCryptos.contains(symbol.toUpperCase());
  }

  /// Get default query parameters for common requests
  static Map<String, String> getDefaultParams() {
    return {instTypeParam: spotInstType};
  }

  /// Get query parameters for supported cryptocurrencies
  static Map<String, String> getSupportedCryptosParams() {
    return {
      instTypeParam: spotInstType,
      instIdParam: getCryptoInstrumentIds().join(','),
    };
  }
}
