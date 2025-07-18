import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/core/constants/constants.dart';

void main() {
  group('AppColors', () {
    group('Primary Colors', () {
      test('should have correct primary color values', () {
        expect(AppColors.primary, equals(const Color(0xFF6750A4)));
        expect(AppColors.primaryLight, equals(const Color(0xFF9A82DB)));
        expect(AppColors.primaryDark, equals(const Color(0xFF4F378B)));
      });
    });

    group('Semantic Colors', () {
      test('should have correct semantic color values', () {
        expect(AppColors.success, equals(const Color(0xFF4CAF50)));
        expect(AppColors.error, equals(const Color(0xFFF44336)));
        expect(AppColors.warning, equals(const Color(0xFFFF9800)));
        expect(AppColors.info, equals(const Color(0xFF2196F3)));
      });
    });

    group('Price Change Colors', () {
      test('should return correct price change colors', () {
        expect(AppColors.getPriceChangeColor(10.0), equals(AppColors.priceUp));
        expect(
          AppColors.getPriceChangeColor(-5.0),
          equals(AppColors.priceDown),
        );
        expect(
          AppColors.getPriceChangeColor(0.0),
          equals(AppColors.priceNeutral),
        );
      });
    });

    group('Connection Status Colors', () {
      test('should return correct connection status colors', () {
        expect(
          AppColors.getConnectionStatusColor('connected'),
          equals(AppColors.connected),
        );
        expect(
          AppColors.getConnectionStatusColor('connecting'),
          equals(AppColors.connecting),
        );
        expect(
          AppColors.getConnectionStatusColor('disconnected'),
          equals(AppColors.disconnected),
        );
        expect(
          AppColors.getConnectionStatusColor('live'),
          equals(AppColors.connected),
        );
        expect(
          AppColors.getConnectionStatusColor('unknown'),
          equals(AppColors.priceNeutral),
        );
      });
    });

    group('Listing Status Colors', () {
      test('should return correct listing status colors', () {
        expect(
          AppColors.getListingStatusColor('active'),
          equals(AppColors.statusActive),
        );
        expect(
          AppColors.getListingStatusColor('delisted'),
          equals(AppColors.statusDelisted),
        );
        expect(
          AppColors.getListingStatusColor('suspended'),
          equals(AppColors.statusSuspended),
        );
        expect(
          AppColors.getListingStatusColor('maintenance'),
          equals(AppColors.statusMaintenance),
        );
        expect(
          AppColors.getListingStatusColor('unknown'),
          equals(AppColors.priceNeutral),
        );
      });
    });

    group('Volume Alert Colors', () {
      test('should return correct volume alert colors', () {
        expect(AppColors.getVolumeAlertColor(150.0), equals(AppColors.error));
        expect(AppColors.getVolumeAlertColor(75.0), equals(AppColors.warning));
        expect(AppColors.getVolumeAlertColor(30.0), equals(AppColors.info));
        expect(
          AppColors.getVolumeAlertColor(10.0),
          equals(AppColors.priceNeutral),
        );
      });
    });

    group('Color Utilities', () {
      test('should create color with opacity correctly', () {
        final colorWithOpacity = AppColors.withOpacity(AppColors.primary, 0.5);
        expect(colorWithOpacity.opacity, closeTo(0.5, 0.01));
      });

      test('should create correct color schemes', () {
        final lightScheme = AppColors.createLightColorScheme();
        final darkScheme = AppColors.createDarkColorScheme();

        expect(lightScheme.brightness, equals(Brightness.light));
        expect(darkScheme.brightness, equals(Brightness.dark));
        expect(lightScheme.primary, equals(AppColors.primary));
        expect(darkScheme.primary, equals(AppColors.primary));
      });

      test('should create price change gradients correctly', () {
        final positiveGradient = AppColors.createPriceChangeGradient(10.0);
        final negativeGradient = AppColors.createPriceChangeGradient(-5.0);
        final neutralGradient = AppColors.createPriceChangeGradient(0.0);

        expect(positiveGradient.colors, equals(AppColors.successGradient));
        expect(negativeGradient.colors, equals(AppColors.errorGradient));
        expect(neutralGradient.colors, equals(AppColors.neutralGradient));
      });

      test('should create shimmer gradient correctly', () {
        final shimmerGradient = AppColors.createShimmerGradient();
        expect(shimmerGradient.colors.length, equals(3));
        expect(shimmerGradient.colors[0], equals(AppColors.shimmerBase));
        expect(shimmerGradient.colors[1], equals(AppColors.shimmerHighlight));
        expect(shimmerGradient.colors[2], equals(AppColors.shimmerBase));
      });

      test('should get crypto colors consistently', () {
        final color1 = AppColors.getCryptoColor('BTC');
        final color2 = AppColors.getCryptoColor('BTC');
        final color3 = AppColors.getCryptoColor('ETH');

        expect(color1, equals(color2)); // Same symbol should return same color
        expect(
          color1,
          isNot(equals(color3)),
        ); // Different symbols should return different colors
        expect(AppColors.chartColors.contains(color1), isTrue);
      });
    });

    group('Accessibility', () {
      test('should validate color accessibility correctly', () {
        // Test with high contrast combinations
        expect(AppColors.isAccessible(Colors.black, Colors.white), isTrue);
        expect(AppColors.isAccessible(Colors.white, Colors.black), isTrue);
        expect(
          AppColors.isAccessible(AppColors.primary, AppColors.primary),
          isFalse,
        );

        // Test the accessibility function works
        expect(
          AppColors.isAccessible(AppColors.textPrimary, AppColors.background),
          isA<bool>(),
        );
      });

      test('should return accessible text colors', () {
        final lightTextColor = AppColors.getAccessibleTextColor(
          AppColors.background,
        );
        final darkTextColor = AppColors.getAccessibleTextColor(
          AppColors.backgroundDark,
        );

        expect(lightTextColor, equals(AppColors.textPrimary));
        expect(darkTextColor, equals(AppColors.textPrimaryDark));
      });
    });

    group('Gradients', () {
      test('should have correct gradient color counts', () {
        expect(AppColors.successGradient.length, equals(2));
        expect(AppColors.errorGradient.length, equals(2));
        expect(AppColors.warningGradient.length, equals(2));
        expect(AppColors.primaryGradient.length, equals(2));
        expect(AppColors.neutralGradient.length, equals(2));
      });
    });

    group('Chart Colors', () {
      test('should have sufficient chart colors', () {
        expect(AppColors.chartColors.length, greaterThanOrEqualTo(8));

        // Check that all colors are unique
        final uniqueColors = AppColors.chartColors.toSet();
        expect(uniqueColors.length, equals(AppColors.chartColors.length));
      });
    });

    group('Color Constants', () {
      test('should have non-null color values', () {
        expect(AppColors.primary, isNotNull);
        expect(AppColors.success, isNotNull);
        expect(AppColors.error, isNotNull);
        expect(AppColors.warning, isNotNull);
        expect(AppColors.info, isNotNull);
        expect(AppColors.background, isNotNull);
        expect(AppColors.surface, isNotNull);
        expect(AppColors.textPrimary, isNotNull);
      });

      test('should have reasonable alpha values for transparent colors', () {
        expect(AppColors.shadowLight.opacity, lessThan(1.0));
        expect(AppColors.shadowMedium.opacity, lessThan(1.0));
        expect(AppColors.shadowDark.opacity, lessThan(1.0));
        expect(AppColors.loadingOverlay.opacity, lessThan(1.0));
        expect(AppColors.modalOverlay.opacity, lessThan(1.0));
      });
    });

    group('Theme Context Methods', () {
      testWidgets('should return correct theme-based colors', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: Builder(
              builder: (context) {
                final textColor = AppColors.getTextColor(context);
                final surfaceColor = AppColors.getSurfaceColor(context);
                final borderColor = AppColors.getBorderColor(context);

                expect(textColor, equals(AppColors.textPrimary));
                expect(surfaceColor, equals(AppColors.surface));
                expect(borderColor, equals(AppColors.border));

                return Container();
              },
            ),
          ),
        );
      });

      testWidgets('should return correct dark theme colors', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: Builder(
              builder: (context) {
                final textColor = AppColors.getTextColor(context);
                final surfaceColor = AppColors.getSurfaceColor(context);
                final borderColor = AppColors.getBorderColor(context);

                expect(textColor, equals(AppColors.textPrimaryDark));
                expect(surfaceColor, equals(AppColors.surfaceDark));
                expect(borderColor, equals(AppColors.borderDark));

                return Container();
              },
            ),
          ),
        );
      });
    });
  });
}
