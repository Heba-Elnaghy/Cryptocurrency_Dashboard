import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/data/mappers/cryptocurrency_mapper.dart';
import 'package:crypto_dashboard/data/models/models.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';

void main() {
  group('CryptocurrencyMapper', () {
    late OKXInstrument testInstrument;
    late OKXTicker testTicker;

    setUp(() {
      testInstrument = const OKXInstrument(
        instId: 'BTC-USDT',
        baseCcy: 'BTC',
        quoteCcy: 'USDT',
        state: 'live',
        instType: 'SPOT',
      );

      testTicker = const OKXTicker(
        instId: 'BTC-USDT',
        last: '50000.0',
        vol24h: '1000000.0',
        volCcy24h: '50000000000.0',
        open24h: '49000.0',
        high24h: '51000.0',
        low24h: '48000.0',
        ts: '1640995200000',
      );
    });

    group('fromOKXData', () {
      test('should map OKX data to Cryptocurrency entity correctly', () {
        // Act
        final cryptocurrency = CryptocurrencyMapper.fromOKXData(
          testInstrument,
          testTicker,
        );

        // Assert
        expect(cryptocurrency.symbol, equals('BTC'));
        expect(cryptocurrency.name, equals('Bitcoin'));
        expect(cryptocurrency.price, equals(50000.0));
        expect(cryptocurrency.priceChange24h, equals(1000.0)); // 50000 - 49000
        expect(cryptocurrency.volume24h, equals(1000000.0));
        expect(cryptocurrency.status, equals(ListingStatus.active));
        expect(cryptocurrency.hasVolumeSpike, equals(false));
        expect(cryptocurrency.lastUpdated, isA<DateTime>());
      });

      test('should handle different listing statuses', () {
        // Test active status
        final activeInstrument = const OKXInstrument(
          instId: 'BTC-USDT',
          baseCcy: 'BTC',
          quoteCcy: 'USDT',
          state: 'live',
          instType: 'SPOT',
        );
        final activeCrypto = CryptocurrencyMapper.fromOKXData(
          activeInstrument,
          testTicker,
        );
        expect(activeCrypto.status, equals(ListingStatus.active));

        // Test suspended status
        final suspendedInstrument = const OKXInstrument(
          instId: 'BTC-USDT',
          baseCcy: 'BTC',
          quoteCcy: 'USDT',
          state: 'suspend',
          instType: 'SPOT',
        );
        final suspendedCrypto = CryptocurrencyMapper.fromOKXData(
          suspendedInstrument,
          testTicker,
        );
        expect(suspendedCrypto.status, equals(ListingStatus.suspended));

        // Test delisted status
        final delistedInstrument = const OKXInstrument(
          instId: 'BTC-USDT',
          baseCcy: 'BTC',
          quoteCcy: 'USDT',
          state: 'delisted',
          instType: 'SPOT',
        );
        final delistedCrypto = CryptocurrencyMapper.fromOKXData(
          delistedInstrument,
          testTicker,
        );
        expect(delistedCrypto.status, equals(ListingStatus.delisted));
      });

      test(
        'should throw DataMappingException when instrument and ticker IDs mismatch',
        () {
          // Arrange
          const mismatchedTicker = OKXTicker(
            instId: 'ETH-USDT',
            last: '50000.0',
            vol24h: '1000000.0',
            volCcy24h: '50000000000.0',
            open24h: '49000.0',
            high24h: '51000.0',
            low24h: '48000.0',
            ts: '1640995200000',
          );

          // Act & Assert
          expect(
            () => CryptocurrencyMapper.fromOKXData(
              testInstrument,
              mismatchedTicker,
            ),
            throwsA(isA<DataMappingException>()),
          );
        },
      );

      test('should throw DataMappingException when price data is invalid', () {
        // Arrange
        const invalidTicker = OKXTicker(
          instId: 'BTC-USDT',
          last: 'invalid',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        // Act & Assert
        expect(
          () => CryptocurrencyMapper.fromOKXData(testInstrument, invalidTicker),
          throwsA(isA<DataMappingException>()),
        );
      });

      test('should handle zero and negative prices', () {
        // Test zero price
        const zeroTicker = OKXTicker(
          instId: 'BTC-USDT',
          last: '0.0',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '0.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );
        final zeroCrypto = CryptocurrencyMapper.fromOKXData(
          testInstrument,
          zeroTicker,
        );
        expect(zeroCrypto.price, equals(0.0));
        expect(zeroCrypto.priceChange24h, equals(0.0));
      });

      test('should parse timestamp correctly', () {
        // Arrange
        const timestampTicker = OKXTicker(
          instId: 'BTC-USDT',
          last: '50000.0',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        // Act
        final crypto = CryptocurrencyMapper.fromOKXData(
          testInstrument,
          timestampTicker,
        );

        // Assert
        expect(
          crypto.lastUpdated.millisecondsSinceEpoch,
          equals(1640995200000),
        );
      });

      test('should handle invalid timestamp gracefully', () {
        // Arrange
        const invalidTimestampTicker = OKXTicker(
          instId: 'BTC-USDT',
          last: '50000.0',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: 'invalid',
        );

        // Act
        final crypto = CryptocurrencyMapper.fromOKXData(
          testInstrument,
          invalidTimestampTicker,
        );

        // Assert - Should use current time as fallback
        expect(crypto.lastUpdated, isA<DateTime>());
        expect(
          crypto.lastUpdated.difference(DateTime.now()).abs().inMinutes,
          lessThan(1),
        );
      });
    });

    group('fromOKXDataList', () {
      test('should map list of instruments and tickers correctly', () {
        // Arrange
        final instruments = [
          testInstrument,
          const OKXInstrument(
            instId: 'ETH-USDT',
            baseCcy: 'ETH',
            quoteCcy: 'USDT',
            state: 'live',
            instType: 'SPOT',
          ),
        ];
        final tickers = [
          testTicker,
          const OKXTicker(
            instId: 'ETH-USDT',
            last: '3000.0',
            vol24h: '500000.0',
            volCcy24h: '1500000000.0',
            open24h: '2950.0',
            high24h: '3100.0',
            low24h: '2900.0',
            ts: '1640995200000',
          ),
        ];

        // Act
        final cryptocurrencies = CryptocurrencyMapper.fromOKXDataList(
          instruments,
          tickers,
        );

        // Assert
        expect(cryptocurrencies, hasLength(2));
        expect(cryptocurrencies[0].symbol, equals('BTC'));
        expect(cryptocurrencies[1].symbol, equals('ETH'));
      });

      test('should handle missing tickers gracefully', () {
        // Arrange
        final instruments = [
          testInstrument,
          const OKXInstrument(
            instId: 'ETH-USDT',
            baseCcy: 'ETH',
            quoteCcy: 'USDT',
            state: 'live',
            instType: 'SPOT',
          ),
        ];
        final tickers = [testTicker]; // Only BTC ticker

        // Act
        final cryptocurrencies = CryptocurrencyMapper.fromOKXDataList(
          instruments,
          tickers,
        );

        // Assert - Should only return BTC
        expect(cryptocurrencies, hasLength(1));
        expect(cryptocurrencies[0].symbol, equals('BTC'));
      });

      test('should handle empty lists', () {
        // Act
        final cryptocurrencies = CryptocurrencyMapper.fromOKXDataList([], []);

        // Assert
        expect(cryptocurrencies, isEmpty);
      });
    });

    group('filterRequiredCryptocurrencies', () {
      test('should filter and order cryptocurrencies correctly', () {
        // Arrange
        final cryptocurrencies = [
          Cryptocurrency(
            symbol: 'ETH',
            name: 'Ethereum',
            price: 3000.0,
            priceChange24h: 100.0,
            volume24h: 500000.0,
            status: ListingStatus.active,
            lastUpdated: DateTime.now(),
            hasVolumeSpike: false,
          ),
          Cryptocurrency(
            symbol: 'BTC',
            name: 'Bitcoin',
            price: 50000.0,
            priceChange24h: 1000.0,
            volume24h: 1000000.0,
            status: ListingStatus.active,
            lastUpdated: DateTime.now(),
            hasVolumeSpike: false,
          ),
          Cryptocurrency(
            symbol: 'UNKNOWN',
            name: 'Unknown',
            price: 1.0,
            priceChange24h: 0.0,
            volume24h: 1000.0,
            status: ListingStatus.active,
            lastUpdated: DateTime.now(),
            hasVolumeSpike: false,
          ),
        ];

        // Act
        final filtered = CryptocurrencyMapper.filterRequiredCryptocurrencies(
          cryptocurrencies,
        );

        // Assert - Should return BTC first, then ETH (in required order)
        expect(filtered, hasLength(2));
        expect(filtered[0].symbol, equals('BTC'));
        expect(filtered[1].symbol, equals('ETH'));
      });

      test(
        'should return empty list when no required cryptocurrencies found',
        () {
          // Arrange
          final cryptocurrencies = [
            Cryptocurrency(
              symbol: 'UNKNOWN',
              name: 'Unknown',
              price: 1.0,
              priceChange24h: 0.0,
              volume24h: 1000.0,
              status: ListingStatus.active,
              lastUpdated: DateTime.now(),
              hasVolumeSpike: false,
            ),
          ];

          // Act
          final filtered = CryptocurrencyMapper.filterRequiredCryptocurrencies(
            cryptocurrencies,
          );

          // Assert
          expect(filtered, isEmpty);
        },
      );
    });

    group('updateWithTicker', () {
      test('should update cryptocurrency with new ticker data', () {
        // Arrange
        final existingCrypto = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 49000.0,
          priceChange24h: 500.0,
          volume24h: 900000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
          hasVolumeSpike: true, // Should be preserved
        );

        const newTicker = OKXTicker(
          instId: 'BTC-USDT',
          last: '51000.0',
          vol24h: '1100000.0',
          volCcy24h: '50000000000.0',
          open24h: '50000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        // Act
        final updatedCrypto = CryptocurrencyMapper.updateWithTicker(
          existingCrypto,
          newTicker,
        );

        // Assert
        expect(updatedCrypto.price, equals(51000.0));
        expect(updatedCrypto.priceChange24h, equals(1000.0)); // 51000 - 50000
        expect(updatedCrypto.volume24h, equals(1100000.0));
        expect(updatedCrypto.hasVolumeSpike, equals(true)); // Preserved
        expect(updatedCrypto.symbol, equals('BTC')); // Unchanged
        expect(updatedCrypto.name, equals('Bitcoin')); // Unchanged
      });

      test('should throw DataMappingException when ticker data is invalid', () {
        // Arrange
        final existingCrypto = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 49000.0,
          priceChange24h: 500.0,
          volume24h: 900000.0,
          status: ListingStatus.active,
          lastUpdated: DateTime.now(),
          hasVolumeSpike: false,
        );

        const invalidTicker = OKXTicker(
          instId: 'BTC-USDT',
          last: 'invalid',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        // Act & Assert
        expect(
          () => CryptocurrencyMapper.updateWithTicker(
            existingCrypto,
            invalidTicker,
          ),
          throwsA(isA<DataMappingException>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle very small decimal values', () {
        // Arrange
        const smallTicker = OKXTicker(
          instId: 'BTC-USDT',
          last: '0.000001',
          vol24h: '1000000000.0',
          volCcy24h: '50000000000.0',
          open24h: '0.0000009',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        // Act
        final crypto = CryptocurrencyMapper.fromOKXData(
          testInstrument,
          smallTicker,
        );

        // Assert
        expect(crypto.price, equals(0.000001));
        expect(crypto.priceChange24h, closeTo(0.0000001, 0.0000001));
      });

      test('should handle very large values', () {
        // Arrange
        const largeTicker = OKXTicker(
          instId: 'BTC-USDT',
          last: '999999999.99',
          vol24h: '999999999999.0',
          volCcy24h: '50000000000.0',
          open24h: '999999999.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        // Act
        final crypto = CryptocurrencyMapper.fromOKXData(
          testInstrument,
          largeTicker,
        );

        // Assert
        expect(crypto.price, equals(999999999.99));
        expect(crypto.volume24h, equals(999999999999.0));
        expect(crypto.priceChange24h, closeTo(0.99, 0.01));
      });

      test('should handle NaN and infinite values', () {
        // Arrange
        const nanTicker = OKXTicker(
          instId: 'BTC-USDT',
          last: 'NaN',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        // Act & Assert
        expect(
          () => CryptocurrencyMapper.fromOKXData(testInstrument, nanTicker),
          throwsA(isA<DataMappingException>()),
        );
      });
    });

    group('Cryptocurrency Name Mapping', () {
      test('should map known symbols to correct names', () {
        final testCases = [
          ('BTC', 'Bitcoin'),
          ('ETH', 'Ethereum'),
          ('XRP', 'XRP'),
          ('BNB', 'BNB'),
          ('SOL', 'Solana'),
          ('DOGE', 'Dogecoin'),
          ('TRX', 'TRON'),
          ('ADA', 'Cardano'),
          ('AVAX', 'Avalanche'),
          ('XLM', 'Stellar'),
        ];

        for (final (symbol, expectedName) in testCases) {
          final instrument = OKXInstrument(
            instId: '$symbol-USDT',
            baseCcy: symbol,
            quoteCcy: 'USDT',
            state: 'live',
            instType: 'SPOT',
          );
          final ticker = OKXTicker(
            instId: '$symbol-USDT',
            last: '50000.0',
            vol24h: '1000000.0',
            volCcy24h: '50000000000.0',
            open24h: '49000.0',
            high24h: '51000.0',
            low24h: '48000.0',
            ts: '1640995200000',
          );

          final crypto = CryptocurrencyMapper.fromOKXData(instrument, ticker);

          expect(
            crypto.name,
            equals(expectedName),
            reason: 'Failed for symbol: $symbol',
          );
        }
      });

      test('should use symbol as name for unknown cryptocurrencies', () {
        // Arrange
        const unknownInstrument = OKXInstrument(
          instId: 'UNKNOWN-USDT',
          baseCcy: 'UNKNOWN',
          quoteCcy: 'USDT',
          state: 'live',
          instType: 'SPOT',
        );
        const unknownTicker = OKXTicker(
          instId: 'UNKNOWN-USDT',
          last: '50000.0',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        // Act
        final crypto = CryptocurrencyMapper.fromOKXData(
          unknownInstrument,
          unknownTicker,
        );

        // Assert
        expect(crypto.name, equals('UNKNOWN'));
      });
    });
  });
}
