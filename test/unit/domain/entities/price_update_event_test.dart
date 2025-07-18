import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';

void main() {
  group('PriceUpdateEvent Entity', () {
    late DateTime testDateTime;

    setUp(() {
      testDateTime = DateTime(2024, 1, 1, 12, 0, 0);
    });

    group('Constructor', () {
      test('should create price update event with all required properties', () {
        // Arrange & Act
        final priceUpdateEvent = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        // Assert
        expect(priceUpdateEvent.symbol, equals('BTC'));
        expect(priceUpdateEvent.newPrice, equals(51000.0));
        expect(priceUpdateEvent.priceChange, equals(1000.0));
        expect(priceUpdateEvent.timestamp, equals(testDateTime));
      });

      test('should create price update event with negative price change', () {
        // Arrange & Act
        final priceUpdateEvent = PriceUpdateEvent(
          symbol: 'ETH',
          newPrice: 2900.0,
          priceChange: -100.0,
          timestamp: testDateTime,
        );

        // Assert
        expect(priceUpdateEvent.symbol, equals('ETH'));
        expect(priceUpdateEvent.newPrice, equals(2900.0));
        expect(priceUpdateEvent.priceChange, equals(-100.0));
        expect(priceUpdateEvent.timestamp, equals(testDateTime));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final event1 = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        final event2 = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        // Act & Assert
        expect(event1, equals(event2));
        expect(event1.hashCode, equals(event2.hashCode));
      });

      test('should not be equal when symbol differs', () {
        // Arrange
        final event1 = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        final event2 = PriceUpdateEvent(
          symbol: 'ETH',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal when newPrice differs', () {
        // Arrange
        final event1 = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        final event2 = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 52000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal when priceChange differs', () {
        // Arrange
        final event1 = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        final event2 = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 2000.0,
          timestamp: testDateTime,
        );

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });

      test('should not be equal when timestamp differs', () {
        // Arrange
        final event1 = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        final event2 = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime.add(const Duration(minutes: 1)),
        );

        // Act & Assert
        expect(event1, isNot(equals(event2)));
      });
    });

    group('Edge Cases', () {
      test('should handle zero price change', () {
        // Arrange & Act
        final priceUpdateEvent = PriceUpdateEvent(
          symbol: 'STABLE',
          newPrice: 1.0,
          priceChange: 0.0,
          timestamp: testDateTime,
        );

        // Assert
        expect(priceUpdateEvent.priceChange, equals(0.0));
        expect(priceUpdateEvent.newPrice, equals(1.0));
      });

      test('should handle very small price values', () {
        // Arrange & Act
        final priceUpdateEvent = PriceUpdateEvent(
          symbol: 'MICRO',
          newPrice: 0.000001,
          priceChange: 0.0000001,
          timestamp: testDateTime,
        );

        // Assert
        expect(priceUpdateEvent.newPrice, equals(0.000001));
        expect(priceUpdateEvent.priceChange, equals(0.0000001));
      });

      test('should handle very large price values', () {
        // Arrange & Act
        final priceUpdateEvent = PriceUpdateEvent(
          symbol: 'EXPENSIVE',
          newPrice: 1000000.0,
          priceChange: 50000.0,
          timestamp: testDateTime,
        );

        // Assert
        expect(priceUpdateEvent.newPrice, equals(1000000.0));
        expect(priceUpdateEvent.priceChange, equals(50000.0));
      });

      test('should handle negative new price (edge case)', () {
        // Arrange & Act
        final priceUpdateEvent = PriceUpdateEvent(
          symbol: 'NEGATIVE',
          newPrice: -1.0,
          priceChange: -2.0,
          timestamp: testDateTime,
        );

        // Assert
        expect(priceUpdateEvent.newPrice, equals(-1.0));
        expect(priceUpdateEvent.priceChange, equals(-2.0));
      });
    });

    group('Business Logic Validation', () {
      test('should represent price increase correctly', () {
        // Arrange & Act
        final priceUpdateEvent = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 51000.0,
          priceChange: 1000.0,
          timestamp: testDateTime,
        );

        // Assert - Price increase scenario
        expect(priceUpdateEvent.priceChange > 0, isTrue);
        expect(priceUpdateEvent.newPrice, equals(51000.0));
      });

      test('should represent price decrease correctly', () {
        // Arrange & Act
        final priceUpdateEvent = PriceUpdateEvent(
          symbol: 'ETH',
          newPrice: 2900.0,
          priceChange: -100.0,
          timestamp: testDateTime,
        );

        // Assert - Price decrease scenario
        expect(priceUpdateEvent.priceChange < 0, isTrue);
        expect(priceUpdateEvent.newPrice, equals(2900.0));
      });

      test('should handle timestamp for real-time updates', () {
        // Arrange
        final now = DateTime.now();

        // Act
        final priceUpdateEvent = PriceUpdateEvent(
          symbol: 'BTC',
          newPrice: 50000.0,
          priceChange: 0.0,
          timestamp: now,
        );

        // Assert - Timestamp should be recent for real-time updates
        final timeDifference = DateTime.now().difference(
          priceUpdateEvent.timestamp,
        );
        expect(timeDifference.inSeconds, lessThan(1));
      });
    });
  });
}
