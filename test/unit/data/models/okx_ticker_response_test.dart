import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/data/models/okx_ticker_response.dart';

void main() {
  group('OKXTickerResponse', () {
    group('fromJson', () {
      test('should create OKXTickerResponse from valid JSON', () {
        // Arrange
        final json = {
          'code': '0',
          'msg': '',
          'data': [
            {
              'instId': 'BTC-USDT',
              'last': '50000.0',
              'vol24h': '1000000.0',
              'volCcy24h': '50000000000.0',
              'open24h': '49000.0',
              'high24h': '51000.0',
              'low24h': '48000.0',
              'ts': '1640995200000',
            },
            {
              'instId': 'ETH-USDT',
              'last': '3000.0',
              'vol24h': '500000.0',
              'volCcy24h': '1500000000.0',
              'open24h': '2950.0',
              'high24h': '3100.0',
              'low24h': '2900.0',
              'ts': '1640995200000',
            },
          ],
        };

        // Act
        final response = OKXTickerResponse.fromJson(json);

        // Assert
        expect(response.code, equals('0'));
        expect(response.msg, equals(''));
        expect(response.data, hasLength(2));
        expect(response.data[0].instId, equals('BTC-USDT'));
        expect(response.data[0].last, equals('50000.0'));
        expect(response.data[1].instId, equals('ETH-USDT'));
        expect(response.data[1].last, equals('3000.0'));
      });

      test('should create OKXTickerResponse with empty data array', () {
        // Arrange
        final json = {
          'code': '0',
          'msg': 'Success',
          'data': <Map<String, dynamic>>[],
        };

        // Act
        final response = OKXTickerResponse.fromJson(json);

        // Assert
        expect(response.code, equals('0'));
        expect(response.msg, equals('Success'));
        expect(response.data, isEmpty);
      });

      test('should handle error response', () {
        // Arrange
        final json = {
          'code': '50001',
          'msg': 'Parameter error',
          'data': <Map<String, dynamic>>[],
        };

        // Act
        final response = OKXTickerResponse.fromJson(json);

        // Assert
        expect(response.code, equals('50001'));
        expect(response.msg, equals('Parameter error'));
        expect(response.data, isEmpty);
      });
    });

    group('toJson', () {
      test('should convert OKXTickerResponse to JSON', () {
        // Arrange
        final response = OKXTickerResponse(
          code: '0',
          msg: 'Success',
          data: [
            const OKXTicker(
              instId: 'BTC-USDT',
              last: '50000.0',
              vol24h: '1000000.0',
              volCcy24h: '50000000000.0',
              open24h: '49000.0',
              high24h: '51000.0',
              low24h: '48000.0',
              ts: '1640995200000',
            ),
          ],
        );

        // Act
        final json = response.toJson();

        // Assert
        expect(json['code'], equals('0'));
        expect(json['msg'], equals('Success'));
        expect(json['data'], hasLength(1));
        expect(json['data'][0], isA<Map<String, dynamic>>());
        final firstTicker = json['data'][0] as Map<String, dynamic>;
        expect(firstTicker['instId'], equals('BTC-USDT'));
        expect(firstTicker['last'], equals('50000.0'));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final response1 = OKXTickerResponse(
          code: '0',
          msg: 'Success',
          data: [
            const OKXTicker(
              instId: 'BTC-USDT',
              last: '50000.0',
              vol24h: '1000000.0',
              volCcy24h: '50000000000.0',
              open24h: '49000.0',
              high24h: '51000.0',
              low24h: '48000.0',
              ts: '1640995200000',
            ),
          ],
        );

        final response2 = OKXTickerResponse(
          code: '0',
          msg: 'Success',
          data: [
            const OKXTicker(
              instId: 'BTC-USDT',
              last: '50000.0',
              vol24h: '1000000.0',
              volCcy24h: '50000000000.0',
              open24h: '49000.0',
              high24h: '51000.0',
              low24h: '48000.0',
              ts: '1640995200000',
            ),
          ],
        );

        // Act & Assert
        expect(response1, equals(response2));
        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('should not be equal when data differs', () {
        // Arrange
        final response1 = OKXTickerResponse(
          code: '0',
          msg: 'Success',
          data: [
            const OKXTicker(
              instId: 'BTC-USDT',
              last: '50000.0',
              vol24h: '1000000.0',
              volCcy24h: '50000000000.0',
              open24h: '49000.0',
              high24h: '51000.0',
              low24h: '48000.0',
              ts: '1640995200000',
            ),
          ],
        );

        final response2 = OKXTickerResponse(
          code: '0',
          msg: 'Success',
          data: [
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
          ],
        );

        // Act & Assert
        expect(response1, isNot(equals(response2)));
      });
    });
  });

  group('OKXTicker', () {
    group('fromJson', () {
      test('should create OKXTicker from valid JSON', () {
        // Arrange
        final json = {
          'instId': 'BTC-USDT',
          'last': '50000.0',
          'vol24h': '1000000.0',
          'volCcy24h': '50000000000.0',
          'open24h': '49000.0',
          'high24h': '51000.0',
          'low24h': '48000.0',
          'ts': '1640995200000',
        };

        // Act
        final ticker = OKXTicker.fromJson(json);

        // Assert
        expect(ticker.instId, equals('BTC-USDT'));
        expect(ticker.last, equals('50000.0'));
        expect(ticker.vol24h, equals('1000000.0'));
        expect(ticker.volCcy24h, equals('50000000000.0'));
        expect(ticker.open24h, equals('49000.0'));
        expect(ticker.high24h, equals('51000.0'));
        expect(ticker.low24h, equals('48000.0'));
        expect(ticker.ts, equals('1640995200000'));
      });

      test('should handle decimal values as strings', () {
        // Arrange
        final json = {
          'instId': 'ETH-USDT',
          'last': '3000.123456',
          'vol24h': '500000.789',
          'volCcy24h': '1500000000.123',
          'open24h': '2950.5',
          'high24h': '3100.99',
          'low24h': '2900.01',
          'ts': '1640995200000',
        };

        // Act
        final ticker = OKXTicker.fromJson(json);

        // Assert
        expect(ticker.last, equals('3000.123456'));
        expect(ticker.vol24h, equals('500000.789'));
        expect(ticker.volCcy24h, equals('1500000000.123'));
        expect(ticker.open24h, equals('2950.5'));
        expect(ticker.high24h, equals('3100.99'));
        expect(ticker.low24h, equals('2900.01'));
      });
    });

    group('toJson', () {
      test('should convert OKXTicker to JSON', () {
        // Arrange
        const ticker = OKXTicker(
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
        final json = ticker.toJson();

        // Assert
        expect(json['instId'], equals('BTC-USDT'));
        expect(json['last'], equals('50000.0'));
        expect(json['vol24h'], equals('1000000.0'));
        expect(json['volCcy24h'], equals('50000000000.0'));
        expect(json['open24h'], equals('49000.0'));
        expect(json['high24h'], equals('51000.0'));
        expect(json['low24h'], equals('48000.0'));
        expect(json['ts'], equals('1640995200000'));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        const ticker1 = OKXTicker(
          instId: 'BTC-USDT',
          last: '50000.0',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        const ticker2 = OKXTicker(
          instId: 'BTC-USDT',
          last: '50000.0',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        // Act & Assert
        expect(ticker1, equals(ticker2));
        expect(ticker1.hashCode, equals(ticker2.hashCode));
      });

      test('should not be equal when last price differs', () {
        // Arrange
        const ticker1 = OKXTicker(
          instId: 'BTC-USDT',
          last: '50000.0',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        const ticker2 = OKXTicker(
          instId: 'BTC-USDT',
          last: '51000.0',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        // Act & Assert
        expect(ticker1, isNot(equals(ticker2)));
      });

      test('should not be equal when timestamp differs', () {
        // Arrange
        const ticker1 = OKXTicker(
          instId: 'BTC-USDT',
          last: '50000.0',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995200000',
        );

        const ticker2 = OKXTicker(
          instId: 'BTC-USDT',
          last: '50000.0',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '49000.0',
          high24h: '51000.0',
          low24h: '48000.0',
          ts: '1640995260000',
        );

        // Act & Assert
        expect(ticker1, isNot(equals(ticker2)));
      });
    });

    group('Edge Cases', () {
      test('should handle zero values', () {
        // Arrange
        final json = {
          'instId': 'TEST-USDT',
          'last': '0.0',
          'vol24h': '0.0',
          'volCcy24h': '0.0',
          'open24h': '0.0',
          'high24h': '0.0',
          'low24h': '0.0',
          'ts': '0',
        };

        // Act
        final ticker = OKXTicker.fromJson(json);

        // Assert
        expect(ticker.last, equals('0.0'));
        expect(ticker.vol24h, equals('0.0'));
        expect(ticker.ts, equals('0'));
      });

      test('should handle very small decimal values', () {
        // Arrange
        final json = {
          'instId': 'MICRO-USDT',
          'last': '0.000001',
          'vol24h': '1000000000.0',
          'volCcy24h': '1000.0',
          'open24h': '0.0000009',
          'high24h': '0.0000012',
          'low24h': '0.0000008',
          'ts': '1640995200000',
        };

        // Act
        final ticker = OKXTicker.fromJson(json);

        // Assert
        expect(ticker.last, equals('0.000001'));
        expect(ticker.open24h, equals('0.0000009'));
        expect(ticker.high24h, equals('0.0000012'));
        expect(ticker.low24h, equals('0.0000008'));
      });

      test('should handle very large values', () {
        // Arrange
        final json = {
          'instId': 'LARGE-USDT',
          'last': '999999999.99',
          'vol24h': '999999999999.0',
          'volCcy24h': '999999999999999.0',
          'open24h': '999999999.0',
          'high24h': '1000000000.0',
          'low24h': '999999998.0',
          'ts': '9999999999999',
        };

        // Act
        final ticker = OKXTicker.fromJson(json);

        // Assert
        expect(ticker.last, equals('999999999.99'));
        expect(ticker.vol24h, equals('999999999999.0'));
        expect(ticker.volCcy24h, equals('999999999999999.0'));
        expect(ticker.ts, equals('9999999999999'));
      });
    });

    group('Business Logic Validation', () {
      test('should represent price increase scenario', () {
        // Arrange
        const ticker = OKXTicker(
          instId: 'BTC-USDT',
          last: '51000.0',
          vol24h: '1000000.0',
          volCcy24h: '50000000000.0',
          open24h: '50000.0',
          high24h: '51500.0',
          low24h: '49500.0',
          ts: '1640995200000',
        );

        // Assert - Price increased from open to last
        final lastPrice = double.parse(ticker.last);
        final openPrice = double.parse(ticker.open24h);
        expect(lastPrice > openPrice, isTrue);
      });

      test('should represent price decrease scenario', () {
        // Arrange
        const ticker = OKXTicker(
          instId: 'ETH-USDT',
          last: '2900.0',
          vol24h: '500000.0',
          volCcy24h: '1500000000.0',
          open24h: '3000.0',
          high24h: '3100.0',
          low24h: '2850.0',
          ts: '1640995200000',
        );

        // Assert - Price decreased from open to last
        final lastPrice = double.parse(ticker.last);
        final openPrice = double.parse(ticker.open24h);
        expect(lastPrice < openPrice, isTrue);
      });

      test('should have consistent high/low values', () {
        // Arrange
        const ticker = OKXTicker(
          instId: 'XRP-USDT',
          last: '0.5',
          vol24h: '100000.0',
          volCcy24h: '50000.0',
          open24h: '0.48',
          high24h: '0.52',
          low24h: '0.46',
          ts: '1640995200000',
        );

        // Assert - High should be >= Low
        final highPrice = double.parse(ticker.high24h);
        final lowPrice = double.parse(ticker.low24h);
        final lastPrice = double.parse(ticker.last);

        expect(highPrice >= lowPrice, isTrue);
        expect(lastPrice >= lowPrice, isTrue);
        expect(lastPrice <= highPrice, isTrue);
      });
    });
  });
}
