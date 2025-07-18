import '../entities/entities.dart';
import '../repositories/cryptocurrency_repository.dart';

/// Use case for fetching the initial list of 10 specific cryptocurrencies
///
/// This use case handles:
/// - Fetching initial cryptocurrency data
/// - Error handling for failed API calls
/// - Validation for required cryptocurrency symbols
///
/// Requirements: 1.1, 1.3, 10.1
class GetInitialCryptocurrencies {
  final CryptocurrencyRepository repository;

  const GetInitialCryptocurrencies(this.repository);

  /// Required cryptocurrency symbols as per requirement 1.1
  static const List<String> requiredSymbols = [
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

  /// Executes the use case to fetch initial cryptocurrencies
  ///
  /// Returns: List of Cryptocurrency entities
  /// Throws: GetInitialCryptocurrenciesException for various error scenarios
  Future<List<Cryptocurrency>> call() async {
    try {
      final cryptocurrencies = await repository.getInitialCryptocurrencies();

      // Validate that we received data
      if (cryptocurrencies.isEmpty) {
        throw GetInitialCryptocurrenciesException(
          'No cryptocurrency data received from API',
          GetInitialCryptocurrenciesErrorType.noData,
        );
      }

      // Validate required symbols are present
      final receivedSymbols = cryptocurrencies
          .map((crypto) => crypto.symbol)
          .toSet();
      final missingSymbols = requiredSymbols
          .where((symbol) => !receivedSymbols.contains(symbol))
          .toList();

      if (missingSymbols.isNotEmpty) {
        throw GetInitialCryptocurrenciesException(
          'Missing required cryptocurrency symbols: ${missingSymbols.join(', ')}',
          GetInitialCryptocurrenciesErrorType.missingSymbols,
          missingSymbols: missingSymbols,
        );
      }

      // Filter to only return the required cryptocurrencies in the specified order
      final orderedCryptocurrencies = <Cryptocurrency>[];
      for (final symbol in requiredSymbols) {
        final crypto = cryptocurrencies.firstWhere(
          (c) => c.symbol == symbol,
          orElse: () => throw GetInitialCryptocurrenciesException(
            'Required cryptocurrency $symbol not found in response',
            GetInitialCryptocurrenciesErrorType.missingSymbols,
            missingSymbols: [symbol],
          ),
        );
        orderedCryptocurrencies.add(crypto);
      }

      return orderedCryptocurrencies;
    } catch (e) {
      if (e is GetInitialCryptocurrenciesException) {
        rethrow;
      }

      // Handle different types of exceptions and convert to domain-specific errors
      throw GetInitialCryptocurrenciesException(
        'Failed to fetch initial cryptocurrencies: ${e.toString()}',
        GetInitialCryptocurrenciesErrorType.apiError,
        originalException: e,
      );
    }
  }
}

/// Exception thrown by GetInitialCryptocurrencies use case
class GetInitialCryptocurrenciesException implements Exception {
  final String message;
  final GetInitialCryptocurrenciesErrorType errorType;
  final List<String>? missingSymbols;
  final Object? originalException;

  const GetInitialCryptocurrenciesException(
    this.message,
    this.errorType, {
    this.missingSymbols,
    this.originalException,
  });

  @override
  String toString() => 'GetInitialCryptocurrenciesException: $message';
}

/// Types of errors that can occur in GetInitialCryptocurrencies use case
enum GetInitialCryptocurrenciesErrorType {
  /// API call failed (network, server error, etc.)
  apiError,

  /// No data received from API
  noData,

  /// Required cryptocurrency symbols are missing
  missingSymbols,

  /// Data validation failed
  validationError,
}
