import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/core/constants/constants.dart';

void main() {
  group('AppTheme', () {
    group('Light Theme', () {
      test('should create light theme with correct properties', () {
        final theme = AppTheme.createLightTheme();

        expect(theme.brightness, equals(Brightness.light));
        expect(theme.colorScheme.primary, equals(AppColors.primary));
        expect(theme.scaffoldBackgroundColor, equals(AppColors.background));
        expect(theme.useMaterial3, isTrue);
      });

      test('should have correct text theme colors', () {
        final theme = AppTheme.createLightTheme();

        expect(theme.textTheme.bodyLarge?.color, equals(AppColors.textPrimary));
        expect(
          theme.textTheme.bodyMedium?.color,
          equals(AppColors.textPrimary),
        );
        expect(
          theme.textTheme.bodySmall?.color,
          equals(AppColors.textSecondary),
        );
      });

      test('should include CryptoDashboardTheme extension', () {
        final theme = AppTheme.createLightTheme();
        final extension = theme.extension<CryptoDashboardTheme>();

        expect(extension, isNotNull);
        expect(extension!.priceUpColor, equals(AppColors.priceUp));
        expect(extension.priceDownColor, equals(AppColors.priceDown));
      });
    });

    group('Dark Theme', () {
      test('should create dark theme with correct properties', () {
        final theme = AppTheme.createDarkTheme();

        expect(theme.brightness, equals(Brightness.dark));
        expect(theme.colorScheme.primary, equals(AppColors.primary));
        expect(theme.scaffoldBackgroundColor, equals(AppColors.backgroundDark));
        expect(theme.useMaterial3, isTrue);
      });

      test('should have correct text theme colors', () {
        final theme = AppTheme.createDarkTheme();

        expect(
          theme.textTheme.bodyLarge?.color,
          equals(AppColors.textPrimaryDark),
        );
        expect(
          theme.textTheme.bodyMedium?.color,
          equals(AppColors.textPrimaryDark),
        );
        expect(
          theme.textTheme.bodySmall?.color,
          equals(AppColors.textSecondaryDark),
        );
      });

      test('should include CryptoDashboardTheme extension', () {
        final theme = AppTheme.createDarkTheme();
        final extension = theme.extension<CryptoDashboardTheme>();

        expect(extension, isNotNull);
        expect(extension!.priceUpColor, equals(AppColors.priceUp));
        expect(extension.priceDownColor, equals(AppColors.priceDown));
      });
    });

    group('CryptoDashboardTheme', () {
      test('should create light theme extension with correct values', () {
        final extension = CryptoDashboardTheme.light();

        expect(extension.priceUpColor, equals(AppColors.priceUp));
        expect(extension.priceDownColor, equals(AppColors.priceDown));
        expect(extension.priceNeutralColor, equals(AppColors.priceNeutral));
        expect(extension.volumeSpikeColor, equals(AppColors.volumeSpike));
        expect(extension.cardBorderColor, equals(AppColors.border));
      });

      test('should create dark theme extension with correct values', () {
        final extension = CryptoDashboardTheme.dark();

        expect(extension.priceUpColor, equals(AppColors.priceUp));
        expect(extension.priceDownColor, equals(AppColors.priceDown));
        expect(extension.priceNeutralColor, equals(AppColors.priceNeutral));
        expect(extension.volumeSpikeColor, equals(AppColors.volumeSpike));
        expect(extension.cardBorderColor, equals(AppColors.borderDark));
      });

      test('should get price change color correctly', () {
        final extension = CryptoDashboardTheme.light();

        expect(extension.getPriceChangeColor(10.0), equals(AppColors.priceUp));
        expect(
          extension.getPriceChangeColor(-5.0),
          equals(AppColors.priceDown),
        );
        expect(
          extension.getPriceChangeColor(0.0),
          equals(AppColors.priceNeutral),
        );
      });

      test('should get price change gradient correctly', () {
        final extension = CryptoDashboardTheme.light();

        final positiveGradient = extension.getPriceChangeGradient(10.0);
        final negativeGradient = extension.getPriceChangeGradient(-5.0);
        final neutralGradient = extension.getPriceChangeGradient(0.0);

        expect(positiveGradient.colors, equals(AppColors.successGradient));
        expect(negativeGradient.colors, equals(AppColors.errorGradient));
        expect(neutralGradient.colors, equals(AppColors.neutralGradient));
      });

      test('should create shimmer gradient correctly', () {
        final extension = CryptoDashboardTheme.light();
        final shimmerGradient = extension.createShimmerGradient();

        expect(shimmerGradient.colors.length, equals(3));
        expect(shimmerGradient.colors[0], equals(extension.shimmerBaseColor));
        expect(
          shimmerGradient.colors[1],
          equals(extension.shimmerHighlightColor),
        );
        expect(shimmerGradient.colors[2], equals(extension.shimmerBaseColor));
      });

      test('should copy with new values correctly', () {
        final original = CryptoDashboardTheme.light();
        final copied =
            original.copyWith(
                  priceUpColor: Colors.green,
                  priceDownColor: Colors.red,
                )
                as CryptoDashboardTheme;

        expect(copied.priceUpColor, equals(Colors.green));
        expect(copied.priceDownColor, equals(Colors.red));
        expect(copied.priceNeutralColor, equals(original.priceNeutralColor));
      });

      testWidgets('should be accessible from BuildContext', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.createLightTheme(),
            home: Builder(
              builder: (context) {
                final theme = CryptoDashboardTheme.of(context);
                expect(theme, isNotNull);
                expect(theme.priceUpColor, equals(AppColors.priceUp));
                return Container();
              },
            ),
          ),
        );
      });
    });
  });
}
