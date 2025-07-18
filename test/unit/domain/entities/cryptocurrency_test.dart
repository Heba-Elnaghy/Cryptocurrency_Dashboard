import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';

void main() {
  group('Cryptocurrency Entity', () {
    late DateTime testDateTime;

    setUp(() {
      testDateTime = DateTime(2024, 1, 1, 12, 0, 0);
    });

    group('Constructor', () {
      test('should create cryptocurrency with all required properties', () {
        // Arrange & Act
        final cryptocurrency = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 1500.0,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
          hasVolumeSpike: true,
        );

        // Assert
        expect(cryptocurrency.symbol, equals('BTC'));
        expect(cryptocurrency.name, equals('Bitcoin'));
        expect(cryptocurrency.price, equals(50000.0));
        expect(cryptocurrency.priceChange24h, equals(1500.0));
        expect(cryptocurrency.volume24h, equals(1000000.0));
        expect(cryptocurrency.status, equals(ListingStatus.active));
        expect(cryptocurrency.lastUpdated, equals(testDateTime));
        expect(cryptocurrency.hasVolumeSpike, isTrue);
      });

      test(
        'should create cryptocurrency with default hasVolumeSpike as false',
        () {
          // Arrange & Act
          final cryptocurrency = Cryptocurrency(
            symbol: 'ETH',
            name: 'Ethereum',
            price: 3000.0,
            priceChange24h: -100.0,
            volume24h: 500000.0,
            status: ListingStatus.active,
            lastUpdated: testDateTime,
          );

          // Assert
          expect(cryptocurrency.hasVolumeSpike, isFalse);
        },
      );
    });

    group('copyWith', () {
      late Cryptocurrency originalCrypto;

      setUp(() {
        originalCrypto = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 1500.0,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
          hasVolumeSpike: false,
        );
      });

      test('should return new instance with updated price', () {
        // Arrange
        const newPrice = 51000.0;

        // Act
        final updatedCrypto = originalCrypto.copyWith(price: newPrice);

        // Assert
        expect(updatedCrypto.price, equals(newPrice));
        expect(updatedCrypto.symbol, equals(originalCrypto.symbol));
        expect(updatedCrypto.name, equals(originalCrypto.name));
        expect(
          updatedCrypto.priceChange24h,
          equals(originalCrypto.priceChange24h),
        );
        expect(updatedCrypto.volume24h, equals(originalCrypto.volume24h));
        expect(updatedCrypto.status, equals(originalCrypto.status));
        expect(updatedCrypto.lastUpdated, equals(originalCrypto.lastUpdated));
        expect(
          updatedCrypto.hasVolumeSpike,
          equals(originalCrypto.hasVolumeSpike),
        );
      });

      test('should return new instance with updated volume spike status', () {
        // Arrange & Act
        final updatedCrypto = originalCrypto.copyWith(hasVolumeSpike: true);

        // Assert
        expect(updatedCrypto.hasVolumeSpike, isTrue);
        expect(updatedCrypto.price, equals(originalCrypto.price));
      });

      test('should return new instance with updated listing status', () {
        // Arrange & Act
        final updatedCrypto = originalCrypto.copyWith(
          status: ListingStatus.delisted,
        );

        // Assert
        expect(updatedCrypto.status, equals(ListingStatus.delisted));
        expect(updatedCrypto.symbol, equals(originalCrypto.symbol));
      });

      test('should return new instance with updated timestamp', () {
        // Arrange
        final newTimestamp = DateTime(2024, 1, 2, 12, 0, 0);

        // Act
        final updatedCrypto = originalCrypto.copyWith(
          lastUpdated: newTimestamp,
        );

        // Assert
        expect(updatedCrypto.lastUpdated, equals(newTimestamp));
        expect(updatedCrypto.symbol, equals(originalCrypto.symbol));
      });

      test('should return identical instance when no parameters provided', () {
        // Act
        final copiedCrypto = originalCrypto.copyWith();

        // Assert
        expect(copiedCrypto.symbol, equals(originalCrypto.symbol));
        expect(copiedCrypto.name, equals(originalCrypto.name));
        expect(copiedCrypto.price, equals(originalCrypto.price));
        expect(
          copiedCrypto.priceChange24h,
          equals(originalCrypto.priceChange24h),
        );
        expect(copiedCrypto.volume24h, equals(originalCrypto.volume24h));
        expect(copiedCrypto.status, equals(originalCrypto.status));
        expect(copiedCrypto.lastUpdated, equals(originalCrypto.lastUpdated));
        expect(
          copiedCrypto.hasVolumeSpike,
          equals(originalCrypto.hasVolumeSpike),
        );
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final crypto1 = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 1500.0,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
          hasVolumeSpike: true,
        );

        final crypto2 = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 1500.0,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
          hasVolumeSpike: true,
        );

        // Act & Assert
        expect(crypto1, equals(crypto2));
        expect(crypto1.hashCode, equals(crypto2.hashCode));
      });

      test('should not be equal when symbol differs', () {
        // Arrange
        final crypto1 = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 1500.0,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
        );

        final crypto2 = Cryptocurrency(
          symbol: 'ETH',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 1500.0,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
        );

        // Act & Assert
        expect(crypto1, isNot(equals(crypto2)));
      });

      test('should not be equal when price differs', () {
        // Arrange
        final crypto1 = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 1500.0,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
        );

        final crypto2 = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 51000.0,
          priceChange24h: 1500.0,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
        );

        // Act & Assert
        expect(crypto1, isNot(equals(crypto2)));
      });

      test('should not be equal when hasVolumeSpike differs', () {
        // Arrange
        final crypto1 = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 1500.0,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
          hasVolumeSpike: true,
        );

        final crypto2 = Cryptocurrency(
          symbol: 'BTC',
          name: 'Bitcoin',
          price: 50000.0,
          priceChange24h: 1500.0,
          volume24h: 1000000.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
          hasVolumeSpike: false,
        );

        // Act & Assert
        expect(crypto1, isNot(equals(crypto2)));
      });
    });

    group('Edge Cases', () {
      test('should handle zero price', () {
        // Arrange & Act
        final cryptocurrency = Cryptocurrency(
          symbol: 'TEST',
          name: 'Test Coin',
          price: 0.0,
          priceChange24h: 0.0,
          volume24h: 0.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
        );

        // Assert
        expect(cryptocurrency.price, equals(0.0));
        expect(cryptocurrency.priceChange24h, equals(0.0));
        expect(cryptocurrency.volume24h, equals(0.0));
      });

      test('should handle negative price change', () {
        // Arrange & Act
        final cryptocurrency = Cryptocurrency(
          symbol: 'TEST',
          name: 'Test Coin',
          price: 100.0,
          priceChange24h: -50.0,
          volume24h: 1000.0,
          status: ListingStatus.active,
          lastUpdated: testDateTime,
        );

        // Assert
        expect(cryptocurrency.priceChange24h, equals(-50.0));
      });

      test('should handle delisted status', () {
        // Arrange & Act
        final cryptocurrency = Cryptocurrency(
          symbol: 'DELIST',
          name: 'Delisted Coin',
          price: 1.0,
          priceChange24h: 0.0,
          volume24h: 0.0,
          status: ListingStatus.delisted,
          lastUpdated: testDateTime,
        );

        // Assert
        expect(cryptocurrency.status, equals(ListingStatus.delisted));
      });
    });
  });
}
