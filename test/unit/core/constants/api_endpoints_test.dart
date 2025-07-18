import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/core/constants/constants.dart';

void main() {
  group('ApiEndpoints', () {
    group('URL Building', () {
      test('should build correct full URL', () {
        const endpoint = '/api/v5/test';
        final result = ApiEndpoints.buildUrl(endpoint);
        expect(result, equals('https://www.okx.com/api/v5/test'));
      });

      test('should build instruments URL with parameters', () {
        final result = ApiEndpoints.buildInstrumentsUrl(
          instType: ApiEndpoints.spotInstType,
        );
        expect(result, contains('instType=SPOT'));
      });

      test('should build tickers URL with parameters', () {
        final result = ApiEndpoints.buildTickersUrl(
          instType: ApiEndpoints.spotInstType,
          instId: 'BTC-USDT',
        );
        expect(result, contains('instType=SPOT'));
        expect(result, contains('instId=BTC-USDT'));
      });
    });

    group('Cryptocurrency Support', () {
      test('should return correct instrument IDs for supported cryptos', () {
        final instrumentIds = ApiEndpoints.getCryptoInstrumentIds();
        expect(instrumentIds, contains('BTC-USDT'));
        expect(instrumentIds, contains('ETH-USDT'));
        expect(instrumentIds, contains('XRP-USDT'));
        expect(instrumentIds.length, equals(10));
      });

      test('should validate supported cryptocurrencies', () {
        expect(ApiEndpoints.isSupportedCrypto('BTC'), isTrue);
        expect(ApiEndpoints.isSupportedCrypto('btc'), isTrue);
        expect(ApiEndpoints.isSupportedCrypto('UNKNOWN'), isFalse);
      });

      test('should get correct instrument ID for symbol', () {
        final result = ApiEndpoints.getInstrumentId('BTC');
        expect(result, equals('BTC-USDT'));

        final resultWithCustomQuote = ApiEndpoints.getInstrumentId(
          'BTC',
          quoteCurrency: 'EUR',
        );
        expect(resultWithCustomQuote, equals('BTC-EUR'));
      });
    });

    group('Validation', () {
      test('should validate instrument types', () {
        expect(ApiEndpoints.isValidInstType(ApiEndpoints.spotInstType), isTrue);
        expect(
          ApiEndpoints.isValidInstType(ApiEndpoints.futuresInstType),
          isTrue,
        );
        expect(ApiEndpoints.isValidInstType('INVALID'), isFalse);
      });

      test('should validate limit parameters', () {
        expect(ApiEndpoints.isValidLimit(100), isTrue);
        expect(ApiEndpoints.isValidLimit(500), isTrue);
        expect(ApiEndpoints.isValidLimit(0), isFalse);
        expect(ApiEndpoints.isValidLimit(1000), isFalse);
      });
    });

    group('Default Parameters', () {
      test('should return correct default parameters', () {
        final params = ApiEndpoints.getDefaultParams();
        expect(
          params[ApiEndpoints.instTypeParam],
          equals(ApiEndpoints.spotInstType),
        );
      });

      test('should return correct supported cryptos parameters', () {
        final params = ApiEndpoints.getSupportedCryptosParams();
        expect(
          params[ApiEndpoints.instTypeParam],
          equals(ApiEndpoints.spotInstType),
        );
        expect(params[ApiEndpoints.instIdParam], isNotNull);
        expect(params[ApiEndpoints.instIdParam], contains('BTC-USDT'));
      });
    });

    group('Constants', () {
      test('should have correct base URL', () {
        expect(ApiEndpoints.baseUrl, equals('https://www.okx.com'));
      });

      test('should have correct API version', () {
        expect(ApiEndpoints.apiVersion, equals('/api/v5'));
      });

      test('should have correct supported cryptocurrencies count', () {
        expect(ApiEndpoints.supportedCryptos.length, equals(10));
      });

      test('should have correct rate limits', () {
        expect(ApiEndpoints.publicRateLimit, equals(20));
        expect(ApiEndpoints.marketDataRateLimit, equals(40));
      });
    });
  });
}
