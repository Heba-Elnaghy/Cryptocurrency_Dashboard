import '../../domain/entities/entities.dart';
import '../models/models.dart';

class CryptocurrencyMapper {
  /// Maps OKX API data to domain Cryptocurrency entity
  /// Combines instrument and ticker data to create a complete cryptocurrency object
  static Cryptocurrency fromOKXData(
    OKXInstrument instrument,
    OKXTicker ticker,
  ) {
    try {
      // Validate that instrument and ticker match
      if (instrument.instId != ticker.instId) {
        throw DataMappingException(
          'Instrument ID mismatch: ${instrument.instId} != ${ticker.instId}',
        );
      }

      // Parse price data with validation
      final price = _parseDouble(ticker.last, 'price');
      final volume24h = _parseDouble(ticker.vol24h, 'volume24h');
      final open24h = _parseDouble(ticker.open24h, 'open24h');

      // Calculate 24h price change
      final priceChange24h = price - open24h;

      // Map listing status
      final status = _mapListingStatus(instrument.state);

      // Parse timestamp
      final lastUpdated = _parseTimestamp(ticker.ts);

      // Create cryptocurrency name from base currency
      final name = _generateCryptocurrencyName(instrument.baseCcy);

      return Cryptocurrency(
        symbol: instrument.baseCcy,
        name: name,
        price: price,
        priceChange24h: priceChange24h,
        volume24h: volume24h,
        status: status,
        lastUpdated: lastUpdated,
        hasVolumeSpike:
            false, // Will be calculated separately by volume detection logic
      );
    } catch (e) {
      throw DataMappingException(
        'Failed to map OKX data for ${instrument.instId}: $e',
      );
    }
  }

  /// Maps a list of OKX instruments and tickers to cryptocurrencies
  /// Filters and matches instruments with their corresponding tickers
  static List<Cryptocurrency> fromOKXDataList(
    List<OKXInstrument> instruments,
    List<OKXTicker> tickers,
  ) {
    final cryptocurrencies = <Cryptocurrency>[];

    // Create a map of tickers for efficient lookup
    final tickerMap = <String, OKXTicker>{};
    for (final ticker in tickers) {
      tickerMap[ticker.instId] = ticker;
    }

    // Process each instrument and find its corresponding ticker
    for (final instrument in instruments) {
      final ticker = tickerMap[instrument.instId];
      if (ticker != null) {
        try {
          final crypto = fromOKXData(instrument, ticker);
          cryptocurrencies.add(crypto);
        } catch (e) {
          // Log error but continue processing other cryptocurrencies
          assert(() {
            // ignore: avoid_print
            print('Warning: Failed to map ${instrument.instId}: $e');
            return true;
          }());
        }
      }
    }

    return cryptocurrencies;
  }

  /// Filters cryptocurrencies to get only the required 10 symbols
  /// Returns cryptocurrencies in the order specified in requirements
  static List<Cryptocurrency> filterRequiredCryptocurrencies(
    List<Cryptocurrency> cryptocurrencies,
  ) {
    const requiredSymbols = [
      'BTC',
      'ETH',
      'XRP',
      'BNB',
      'SOL',
      'DOGE',
      'TRX',
      'ADA',
      'AVAX',
      'XLM',
    ];

    final cryptoMap = <String, Cryptocurrency>{};
    for (final crypto in cryptocurrencies) {
      cryptoMap[crypto.symbol] = crypto;
    }

    final filteredCryptos = <Cryptocurrency>[];
    for (final symbol in requiredSymbols) {
      final crypto = cryptoMap[symbol];
      if (crypto != null) {
        filteredCryptos.add(crypto);
      }
    }

    return filteredCryptos;
  }

  /// Updates a cryptocurrency with new ticker data
  /// Preserves existing volume spike status and other calculated fields
  static Cryptocurrency updateWithTicker(
    Cryptocurrency existing,
    OKXTicker ticker,
  ) {
    try {
      final price = _parseDouble(ticker.last, 'price');
      final volume24h = _parseDouble(ticker.vol24h, 'volume24h');
      final open24h = _parseDouble(ticker.open24h, 'open24h');
      final priceChange24h = price - open24h;
      final lastUpdated = _parseTimestamp(ticker.ts);

      return existing.copyWith(
        price: price,
        priceChange24h: priceChange24h,
        volume24h: volume24h,
        lastUpdated: lastUpdated,
        // Preserve existing hasVolumeSpike status
      );
    } catch (e) {
      throw DataMappingException(
        'Failed to update cryptocurrency ${existing.symbol}: $e',
      );
    }
  }

  // Private helper methods

  static double _parseDouble(String value, String fieldName) {
    try {
      final parsed = double.parse(value);
      if (parsed.isNaN || parsed.isInfinite) {
        throw FormatException('Invalid number: $value');
      }
      return parsed;
    } catch (e) {
      throw DataMappingException('Failed to parse $fieldName: $value ($e)');
    }
  }

  static ListingStatus _mapListingStatus(String state) {
    switch (state.toLowerCase()) {
      case 'live':
      case 'active':
        return ListingStatus.active;
      case 'suspend':
      case 'suspended':
        return ListingStatus.suspended;
      case 'preopen':
      case 'delisted':
        return ListingStatus.delisted;
      default:
        // Default to active for unknown states
        return ListingStatus.active;
    }
  }

  static DateTime _parseTimestamp(String timestamp) {
    try {
      final milliseconds = int.parse(timestamp);
      return DateTime.fromMillisecondsSinceEpoch(milliseconds);
    } catch (e) {
      // Fallback to current time if timestamp parsing fails
      return DateTime.now();
    }
  }

  static String _generateCryptocurrencyName(String symbol) {
    // Map common cryptocurrency symbols to their full names
    const symbolToName = {
      'BTC': 'Bitcoin',
      'ETH': 'Ethereum',
      'XRP': 'XRP',
      'BNB': 'BNB',
      'SOL': 'Solana',
      'DOGE': 'Dogecoin',
      'TRX': 'TRON',
      'ADA': 'Cardano',
      'AVAX': 'Avalanche',
      'XLM': 'Stellar',
    };

    return symbolToName[symbol] ?? symbol;
  }
}

/// Custom exception for data mapping errors
class DataMappingException implements Exception {
  final String message;

  const DataMappingException(this.message);

  @override
  String toString() => 'DataMappingException: $message';
}
