import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';

void main() {
  group('VolumeAlert Entity', () {
    group('Constructor', () {
      test('should create volume alert with all required properties', () {
        // Arrange & Act
        final volumeAlert = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        // Assert
        expect(volumeAlert.symbol, equals('BTC'));
        expect(volumeAlert.currentVolume, equals(1500000.0));
        expect(volumeAlert.previousVolume, equals(1000000.0));
        expect(volumeAlert.spikePercentage, equals(0.5));
      });

      test('should create volume alert with high spike percentage', () {
        // Arrange & Act
        final volumeAlert = VolumeAlert(
          symbol: 'ETH',
          currentVolume: 2000000.0,
          previousVolume: 500000.0,
          spikePercentage: 3.0, // 300% increase
        );

        // Assert
        expect(volumeAlert.symbol, equals('ETH'));
        expect(volumeAlert.currentVolume, equals(2000000.0));
        expect(volumeAlert.previousVolume, equals(500000.0));
        expect(volumeAlert.spikePercentage, equals(3.0));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final alert1 = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        final alert2 = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        // Act & Assert
        expect(alert1, equals(alert2));
        expect(alert1.hashCode, equals(alert2.hashCode));
      });

      test('should not be equal when symbol differs', () {
        // Arrange
        final alert1 = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        final alert2 = VolumeAlert(
          symbol: 'ETH',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        // Act & Assert
        expect(alert1, isNot(equals(alert2)));
      });

      test('should not be equal when currentVolume differs', () {
        // Arrange
        final alert1 = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        final alert2 = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1600000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        // Act & Assert
        expect(alert1, isNot(equals(alert2)));
      });

      test('should not be equal when previousVolume differs', () {
        // Arrange
        final alert1 = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        final alert2 = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 900000.0,
          spikePercentage: 0.5,
        );

        // Act & Assert
        expect(alert1, isNot(equals(alert2)));
      });

      test('should not be equal when spikePercentage differs', () {
        // Arrange
        final alert1 = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        final alert2 = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.6,
        );

        // Act & Assert
        expect(alert1, isNot(equals(alert2)));
      });
    });

    group('Business Logic Validation', () {
      test('should represent 50% volume spike correctly', () {
        // Arrange & Act
        final volumeAlert = VolumeAlert(
          symbol: 'BTC',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5,
        );

        // Assert - 50% spike threshold
        expect(volumeAlert.spikePercentage, equals(0.5));
        expect(volumeAlert.spikePercentage >= 0.5, isTrue);

        // Verify the calculation makes sense
        final expectedIncrease =
            volumeAlert.currentVolume - volumeAlert.previousVolume;
        final expectedPercentage =
            expectedIncrease / volumeAlert.previousVolume;
        expect(volumeAlert.spikePercentage, equals(expectedPercentage));
      });

      test('should represent 100% volume spike correctly', () {
        // Arrange & Act
        final volumeAlert = VolumeAlert(
          symbol: 'ETH',
          currentVolume: 2000000.0,
          previousVolume: 1000000.0,
          spikePercentage: 1.0,
        );

        // Assert - 100% spike (double the volume)
        expect(volumeAlert.spikePercentage, equals(1.0));
        expect(
          volumeAlert.currentVolume,
          equals(volumeAlert.previousVolume * 2),
        );
      });

      test('should handle minimal spike above threshold', () {
        // Arrange & Act
        final volumeAlert = VolumeAlert(
          symbol: 'XRP',
          currentVolume: 1500001.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5000001,
        );

        // Assert - Just above 50% threshold
        expect(volumeAlert.spikePercentage > 0.5, isTrue);
      });

      test('should handle very high volume spikes', () {
        // Arrange & Act
        final volumeAlert = VolumeAlert(
          symbol: 'DOGE',
          currentVolume: 10000000.0,
          previousVolume: 1000000.0,
          spikePercentage: 9.0, // 900% increase
        );

        // Assert - Extreme volume spike
        expect(volumeAlert.spikePercentage, equals(9.0));
        expect(
          volumeAlert.currentVolume,
          equals(volumeAlert.previousVolume * 10),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle zero previous volume', () {
        // Arrange & Act
        final volumeAlert = VolumeAlert(
          symbol: 'NEW',
          currentVolume: 1000000.0,
          previousVolume: 0.0,
          spikePercentage: double.infinity,
        );

        // Assert - Infinite spike when previous volume is zero
        expect(volumeAlert.previousVolume, equals(0.0));
        expect(volumeAlert.spikePercentage, equals(double.infinity));
      });

      test('should handle very small volume values', () {
        // Arrange & Act
        final volumeAlert = VolumeAlert(
          symbol: 'MICRO',
          currentVolume: 0.0015,
          previousVolume: 0.001,
          spikePercentage: 0.5,
        );

        // Assert
        expect(volumeAlert.currentVolume, equals(0.0015));
        expect(volumeAlert.previousVolume, equals(0.001));
        expect(volumeAlert.spikePercentage, equals(0.5));
      });

      test('should handle very large volume values', () {
        // Arrange & Act
        final volumeAlert = VolumeAlert(
          symbol: 'WHALE',
          currentVolume: 1000000000000.0, // 1 trillion
          previousVolume: 500000000000.0, // 500 billion
          spikePercentage: 1.0,
        );

        // Assert
        expect(volumeAlert.currentVolume, equals(1000000000000.0));
        expect(volumeAlert.previousVolume, equals(500000000000.0));
        expect(volumeAlert.spikePercentage, equals(1.0));
      });

      test('should handle negative spike percentage (volume decrease)', () {
        // Arrange & Act - This represents a volume drop, not a spike
        final volumeAlert = VolumeAlert(
          symbol: 'DROP',
          currentVolume: 500000.0,
          previousVolume: 1000000.0,
          spikePercentage: -0.5, // 50% decrease
        );

        // Assert
        expect(volumeAlert.spikePercentage, equals(-0.5));
        expect(volumeAlert.spikePercentage < 0, isTrue);
      });

      test('should handle exact threshold spike', () {
        // Arrange & Act
        final volumeAlert = VolumeAlert(
          symbol: 'EXACT',
          currentVolume: 1500000.0,
          previousVolume: 1000000.0,
          spikePercentage: 0.5, // Exactly 50%
        );

        // Assert - Exactly at threshold
        expect(volumeAlert.spikePercentage, equals(0.5));
        expect(volumeAlert.spikePercentage >= 0.5, isTrue);
      });
    });

    group('Calculation Verification', () {
      test('should verify spike percentage calculation is consistent', () {
        // Arrange
        const currentVol = 1800000.0;
        const previousVol = 1200000.0;
        const expectedSpike = (currentVol - previousVol) / previousVol;

        // Act
        final volumeAlert = VolumeAlert(
          symbol: 'CALC',
          currentVolume: currentVol,
          previousVolume: previousVol,
          spikePercentage: expectedSpike,
        );

        // Assert
        expect(volumeAlert.spikePercentage, equals(expectedSpike));
        expect(volumeAlert.spikePercentage, closeTo(0.5, 0.001));
      });

      test('should verify multiple spike scenarios', () {
        // Test data: [currentVol, previousVol, expectedSpike]
        final testCases = [
          [1500000.0, 1000000.0, 0.5], // 50% increase
          [2000000.0, 1000000.0, 1.0], // 100% increase
          [1750000.0, 1000000.0, 0.75], // 75% increase
          [1100000.0, 1000000.0, 0.1], // 10% increase
        ];

        for (final testCase in testCases) {
          // Arrange
          final currentVol = testCase[0];
          final previousVol = testCase[1];
          final expectedSpike = testCase[2];

          // Act
          final volumeAlert = VolumeAlert(
            symbol: 'TEST',
            currentVolume: currentVol,
            previousVolume: previousVol,
            spikePercentage: expectedSpike,
          );

          // Assert
          expect(
            volumeAlert.spikePercentage,
            closeTo(expectedSpike, 0.001),
            reason: 'Failed for current: $currentVol, previous: $previousVol',
          );
        }
      });
    });
  });
}
