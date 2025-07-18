import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/core/constants/constants.dart';

void main() {
  group('AppConstants', () {
    group('Validation', () {
      test('should validate price values correctly', () {
        expect(AppConstants.isValidPrice(100.0), isTrue);
        expect(AppConstants.isValidPrice(0.000001), isTrue);
        expect(AppConstants.isValidPrice(0.0), isFalse);
        expect(AppConstants.isValidPrice(2000000.0), isFalse);
      });

      test('should validate volume values correctly', () {
        expect(AppConstants.isValidVolume(1000.0), isTrue);
        expect(AppConstants.isValidVolume(0.0), isTrue);
        expect(AppConstants.isValidVolume(-100.0), isFalse);
        expect(AppConstants.isValidVolume(2000000000.0), isFalse);
      });
    });

    group('Formatting', () {
      test('should format prices correctly', () {
        expect(AppConstants.formatPrice(100.123), equals('100.12'));
        expect(AppConstants.formatPrice(0.1234), equals('0.1234'));
        expect(AppConstants.formatPrice(0.00001234), equals('0.00001234'));
      });

      test('should format volumes correctly', () {
        expect(AppConstants.formatVolume(1500000), equals('1.5M'));
        expect(AppConstants.formatVolume(1500), equals('1.5K'));
        expect(AppConstants.formatVolume(150), equals('150.00'));
      });
    });

    group('Price Change Detection', () {
      test('should detect significant price changes', () {
        expect(AppConstants.isSignificantPriceChange(6.0), isTrue);
        expect(AppConstants.isSignificantPriceChange(-6.0), isTrue);
        expect(AppConstants.isSignificantPriceChange(3.0), isFalse);
        expect(AppConstants.isSignificantPriceChange(-3.0), isFalse);
      });
    });

    group('Volume Spike Detection', () {
      test('should detect volume spikes correctly', () {
        expect(AppConstants.isVolumeSpikeDetected(1500, 1000), isTrue);
        expect(AppConstants.isVolumeSpikeDetected(1200, 1000), isFalse);
        expect(
          AppConstants.isVolumeSpikeDetected(500, 300),
          isFalse,
        ); // Below minimum volume
      });
    });

    group('Retry Logic', () {
      test('should calculate retry delays correctly', () {
        final delay1 = AppConstants.getRetryDelay(1);
        final delay2 = AppConstants.getRetryDelay(2);
        final delay3 = AppConstants.getRetryDelay(3);

        expect(delay1.inSeconds, equals(2));
        expect(delay2.inSeconds, equals(4));
        expect(delay3.inSeconds, equals(6));
      });

      test('should cap retry delays at maximum', () {
        final delay = AppConstants.getRetryDelay(20);
        expect(delay.inSeconds, lessThanOrEqualTo(30));
      });
    });

    group('Cache Keys', () {
      test('should generate correct cache keys', () {
        final key = AppConstants.getCacheKey('BTC');
        expect(key, equals('crypto_dashboard_cache_crypto_BTC'));
      });
    });

    group('Duration Helpers', () {
      test('should return correct durations', () {
        expect(AppConstants.defaultUpdateInterval.inSeconds, equals(3));
        expect(AppConstants.backgroundUpdateInterval.inMinutes, equals(5));
        expect(AppConstants.cacheExpiry.inMinutes, equals(15));
        expect(AppConstants.connectionTimeout.inSeconds, equals(30));
      });
    });

    group('Constants Values', () {
      test('should have correct app information', () {
        expect(AppConstants.appName, equals('Crypto Dashboard'));
        expect(AppConstants.appVersion, equals('1.0.0'));
        expect(AppConstants.appDescription, isNotEmpty);
      });

      test('should have reasonable default values', () {
        expect(AppConstants.defaultUpdateIntervalSeconds, greaterThan(0));
        expect(AppConstants.maxRetryAttempts, greaterThan(0));
        expect(AppConstants.volumeSpikeThreshold, greaterThan(0));
        expect(AppConstants.significantPriceChangeThreshold, greaterThan(0));
      });
    });
  });
}
