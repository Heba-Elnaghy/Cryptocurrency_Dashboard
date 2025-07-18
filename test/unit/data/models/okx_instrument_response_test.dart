import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/data/models/okx_instrument_response.dart';

void main() {
  group('OKXInstrumentResponse', () {
    group('fromJson', () {
      test('should create OKXInstrumentResponse from valid JSON', () {
        // Arrange
        final json = {
          'code': '0',
          'msg': '',
          'data': [
            {
              'instId': 'BTC-USDT',
              'baseCcy': 'BTC',
              'quoteCcy': 'USDT',
              'state': 'live',
              'instType': 'SPOT',
            },
            {
              'instId': 'ETH-USDT',
              'baseCcy': 'ETH',
              'quoteCcy': 'USDT',
              'state': 'live',
              'instType': 'SPOT',
            },
          ],
        };

        // Act
        final response = OKXInstrumentResponse.fromJson(json);

        // Assert
        expect(response.code, equals('0'));
        expect(response.msg, equals(''));
        expect(response.data, hasLength(2));
        expect(response.data[0].instId, equals('BTC-USDT'));
        expect(response.data[0].baseCcy, equals('BTC'));
        expect(response.data[1].instId, equals('ETH-USDT'));
        expect(response.data[1].baseCcy, equals('ETH'));
      });

      test('should create OKXInstrumentResponse with empty data array', () {
        // Arrange
        final json = {
          'code': '0',
          'msg': 'Success',
          'data': <Map<String, dynamic>>[],
        };

        // Act
        final response = OKXInstrumentResponse.fromJson(json);

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
        final response = OKXInstrumentResponse.fromJson(json);

        // Assert
        expect(response.code, equals('50001'));
        expect(response.msg, equals('Parameter error'));
        expect(response.data, isEmpty);
      });
    });

    group('toJson', () {
      test('should convert OKXInstrumentResponse to JSON', () {
        // Arrange
        final response = OKXInstrumentResponse(
          code: '0',
          msg: 'Success',
          data: [
            const OKXInstrument(
              instId: 'BTC-USDT',
              baseCcy: 'BTC',
              quoteCcy: 'USDT',
              state: 'live',
              instType: 'SPOT',
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
        final firstInstrument = json['data'][0] as Map<String, dynamic>;
        expect(firstInstrument['instId'], equals('BTC-USDT'));
        expect(firstInstrument['baseCcy'], equals('BTC'));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final response1 = OKXInstrumentResponse(
          code: '0',
          msg: 'Success',
          data: [
            const OKXInstrument(
              instId: 'BTC-USDT',
              baseCcy: 'BTC',
              quoteCcy: 'USDT',
              state: 'live',
              instType: 'SPOT',
            ),
          ],
        );

        final response2 = OKXInstrumentResponse(
          code: '0',
          msg: 'Success',
          data: [
            const OKXInstrument(
              instId: 'BTC-USDT',
              baseCcy: 'BTC',
              quoteCcy: 'USDT',
              state: 'live',
              instType: 'SPOT',
            ),
          ],
        );

        // Act & Assert
        expect(response1, equals(response2));
        expect(response1.hashCode, equals(response2.hashCode));
      });

      test('should not be equal when code differs', () {
        // Arrange
        final response1 = OKXInstrumentResponse(
          code: '0',
          msg: 'Success',
          data: [],
        );

        final response2 = OKXInstrumentResponse(
          code: '50001',
          msg: 'Success',
          data: [],
        );

        // Act & Assert
        expect(response1, isNot(equals(response2)));
      });
    });
  });

  group('OKXInstrument', () {
    group('fromJson', () {
      test('should create OKXInstrument from valid JSON', () {
        // Arrange
        final json = {
          'instId': 'BTC-USDT',
          'baseCcy': 'BTC',
          'quoteCcy': 'USDT',
          'state': 'live',
          'instType': 'SPOT',
        };

        // Act
        final instrument = OKXInstrument.fromJson(json);

        // Assert
        expect(instrument.instId, equals('BTC-USDT'));
        expect(instrument.baseCcy, equals('BTC'));
        expect(instrument.quoteCcy, equals('USDT'));
        expect(instrument.state, equals('live'));
        expect(instrument.instType, equals('SPOT'));
      });

      test('should handle different states', () {
        // Arrange
        final states = ['live', 'suspend', 'preopen', 'delisted'];

        for (final state in states) {
          final json = {
            'instId': 'TEST-USDT',
            'baseCcy': 'TEST',
            'quoteCcy': 'USDT',
            'state': state,
            'instType': 'SPOT',
          };

          // Act
          final instrument = OKXInstrument.fromJson(json);

          // Assert
          expect(instrument.state, equals(state));
        }
      });
    });

    group('toJson', () {
      test('should convert OKXInstrument to JSON', () {
        // Arrange
        const instrument = OKXInstrument(
          instId: 'ETH-USDT',
          baseCcy: 'ETH',
          quoteCcy: 'USDT',
          state: 'live',
          instType: 'SPOT',
        );

        // Act
        final json = instrument.toJson();

        // Assert
        expect(json['instId'], equals('ETH-USDT'));
        expect(json['baseCcy'], equals('ETH'));
        expect(json['quoteCcy'], equals('USDT'));
        expect(json['state'], equals('live'));
        expect(json['instType'], equals('SPOT'));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        const instrument1 = OKXInstrument(
          instId: 'BTC-USDT',
          baseCcy: 'BTC',
          quoteCcy: 'USDT',
          state: 'live',
          instType: 'SPOT',
        );

        const instrument2 = OKXInstrument(
          instId: 'BTC-USDT',
          baseCcy: 'BTC',
          quoteCcy: 'USDT',
          state: 'live',
          instType: 'SPOT',
        );

        // Act & Assert
        expect(instrument1, equals(instrument2));
        expect(instrument1.hashCode, equals(instrument2.hashCode));
      });

      test('should not be equal when instId differs', () {
        // Arrange
        const instrument1 = OKXInstrument(
          instId: 'BTC-USDT',
          baseCcy: 'BTC',
          quoteCcy: 'USDT',
          state: 'live',
          instType: 'SPOT',
        );

        const instrument2 = OKXInstrument(
          instId: 'ETH-USDT',
          baseCcy: 'BTC',
          quoteCcy: 'USDT',
          state: 'live',
          instType: 'SPOT',
        );

        // Act & Assert
        expect(instrument1, isNot(equals(instrument2)));
      });
    });

    group('Edge Cases', () {
      test('should handle empty strings', () {
        // Arrange
        final json = {
          'instId': '',
          'baseCcy': '',
          'quoteCcy': '',
          'state': '',
          'instType': '',
        };

        // Act
        final instrument = OKXInstrument.fromJson(json);

        // Assert
        expect(instrument.instId, equals(''));
        expect(instrument.baseCcy, equals(''));
        expect(instrument.quoteCcy, equals(''));
        expect(instrument.state, equals(''));
        expect(instrument.instType, equals(''));
      });

      test('should handle special characters in instrument data', () {
        // Arrange
        final json = {
          'instId': 'BTC-USDT',
          'baseCcy': 'BTC',
          'quoteCcy': 'USDT',
          'state': 'live',
          'instType': 'SPOT',
        };

        // Act
        final instrument = OKXInstrument.fromJson(json);

        // Assert
        expect(instrument.instId, contains('-'));
        expect(instrument.baseCcy, equals('BTC'));
      });
    });
  });
}
