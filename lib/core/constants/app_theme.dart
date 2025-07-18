import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Application theme configuration for the crypto dashboard
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // ==================== Light Theme ====================

  /// Create the light theme for the application
  static ThemeData createLightTheme() {
    final colorScheme = AppColors.createLightColorScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: AppColors.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.divider,
        thickness: 1.0,
        space: 1.0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        disabledColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        secondarySelectedColor: colorScheme.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
        ),
        labelStyle: const TextStyle(fontSize: 14.0),
        secondaryLabelStyle: const TextStyle(fontSize: 14.0),
        brightness: Brightness.light,
      ),
      textTheme: _createTextTheme(Brightness.light),
      extensions: [CryptoDashboardTheme.light()],
    );
  }

  // ==================== Dark Theme ====================

  /// Create the dark theme for the application
  static ThemeData createDarkTheme() {
    final colorScheme = AppColors.createDarkColorScheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackgroundDark,
        elevation: AppColors.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1.0,
        space: 1.0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        disabledColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        secondarySelectedColor: colorScheme.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
        ),
        labelStyle: const TextStyle(fontSize: 14.0),
        secondaryLabelStyle: const TextStyle(fontSize: 14.0),
        brightness: Brightness.dark,
      ),
      textTheme: _createTextTheme(Brightness.dark),
      extensions: [CryptoDashboardTheme.dark()],
    );
  }

  // ==================== Helper Methods ====================

  /// Create text theme based on brightness
  static TextTheme _createTextTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final textColor = isLight
        ? AppColors.textPrimary
        : AppColors.textPrimaryDark;
    final secondaryTextColor = isLight
        ? AppColors.textSecondary
        : AppColors.textSecondaryDark;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57.0,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: 45.0,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: 36.0,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28.0,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24.0,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22.0,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
        color: secondaryTextColor,
      ),
      labelLarge: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11.0,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
    );
  }
}

/// Custom theme extension for crypto dashboard specific styles
class CryptoDashboardTheme extends ThemeExtension<CryptoDashboardTheme> {
  final Color priceUpColor;
  final Color priceDownColor;
  final Color priceNeutralColor;
  final Color volumeSpikeColor;
  final Color connectionStatusColor;
  final Color cardBorderColor;
  final Color shimmerBaseColor;
  final Color shimmerHighlightColor;
  final LinearGradient successGradient;
  final LinearGradient errorGradient;
  final LinearGradient warningGradient;
  final LinearGradient neutralGradient;
  final BorderRadius defaultBorderRadius;
  final EdgeInsets defaultPadding;
  final Duration defaultAnimationDuration;

  CryptoDashboardTheme({
    required this.priceUpColor,
    required this.priceDownColor,
    required this.priceNeutralColor,
    required this.volumeSpikeColor,
    required this.connectionStatusColor,
    required this.cardBorderColor,
    required this.shimmerBaseColor,
    required this.shimmerHighlightColor,
    required this.successGradient,
    required this.errorGradient,
    required this.warningGradient,
    required this.neutralGradient,
    required this.defaultBorderRadius,
    required this.defaultPadding,
    required this.defaultAnimationDuration,
  });

  /// Create light theme extension
  factory CryptoDashboardTheme.light() {
    return CryptoDashboardTheme(
      priceUpColor: AppColors.priceUp,
      priceDownColor: AppColors.priceDown,
      priceNeutralColor: AppColors.priceNeutral,
      volumeSpikeColor: AppColors.volumeSpike,
      connectionStatusColor: AppColors.connected,
      cardBorderColor: AppColors.border,
      shimmerBaseColor: AppColors.shimmerBase,
      shimmerHighlightColor: AppColors.shimmerHighlight,
      successGradient: const LinearGradient(
        colors: AppColors.successGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      errorGradient: const LinearGradient(
        colors: AppColors.errorGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      warningGradient: const LinearGradient(
        colors: AppColors.warningGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      neutralGradient: const LinearGradient(
        colors: AppColors.neutralGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      defaultBorderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
      defaultPadding: const EdgeInsets.all(16.0),
      defaultAnimationDuration: const Duration(milliseconds: 300),
    );
  }

  /// Create dark theme extension
  factory CryptoDashboardTheme.dark() {
    return CryptoDashboardTheme(
      priceUpColor: AppColors.priceUp,
      priceDownColor: AppColors.priceDown,
      priceNeutralColor: AppColors.priceNeutral,
      volumeSpikeColor: AppColors.volumeSpike,
      connectionStatusColor: AppColors.connected,
      cardBorderColor: AppColors.borderDark,
      shimmerBaseColor: const Color(0xFF424242),
      shimmerHighlightColor: const Color(0xFF616161),
      successGradient: const LinearGradient(
        colors: AppColors.successGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      errorGradient: const LinearGradient(
        colors: AppColors.errorGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      warningGradient: const LinearGradient(
        colors: AppColors.warningGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      neutralGradient: const LinearGradient(
        colors: [Color(0xFF424242), Color(0xFF616161)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      defaultBorderRadius: BorderRadius.circular(AppColors.defaultBorderRadius),
      defaultPadding: const EdgeInsets.all(16.0),
      defaultAnimationDuration: const Duration(milliseconds: 300),
    );
  }

  @override
  ThemeExtension<CryptoDashboardTheme> copyWith({
    Color? priceUpColor,
    Color? priceDownColor,
    Color? priceNeutralColor,
    Color? volumeSpikeColor,
    Color? connectionStatusColor,
    Color? cardBorderColor,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    LinearGradient? successGradient,
    LinearGradient? errorGradient,
    LinearGradient? warningGradient,
    LinearGradient? neutralGradient,
    BorderRadius? defaultBorderRadius,
    EdgeInsets? defaultPadding,
    Duration? defaultAnimationDuration,
  }) {
    return CryptoDashboardTheme(
      priceUpColor: priceUpColor ?? this.priceUpColor,
      priceDownColor: priceDownColor ?? this.priceDownColor,
      priceNeutralColor: priceNeutralColor ?? this.priceNeutralColor,
      volumeSpikeColor: volumeSpikeColor ?? this.volumeSpikeColor,
      connectionStatusColor:
          connectionStatusColor ?? this.connectionStatusColor,
      cardBorderColor: cardBorderColor ?? this.cardBorderColor,
      shimmerBaseColor: shimmerBaseColor ?? this.shimmerBaseColor,
      shimmerHighlightColor:
          shimmerHighlightColor ?? this.shimmerHighlightColor,
      successGradient: successGradient ?? this.successGradient,
      errorGradient: errorGradient ?? this.errorGradient,
      warningGradient: warningGradient ?? this.warningGradient,
      neutralGradient: neutralGradient ?? this.neutralGradient,
      defaultBorderRadius: defaultBorderRadius ?? this.defaultBorderRadius,
      defaultPadding: defaultPadding ?? this.defaultPadding,
      defaultAnimationDuration:
          defaultAnimationDuration ?? this.defaultAnimationDuration,
    );
  }

  @override
  ThemeExtension<CryptoDashboardTheme> lerp(
    covariant ThemeExtension<CryptoDashboardTheme>? other,
    double t,
  ) {
    if (other is! CryptoDashboardTheme) {
      return this;
    }

    return CryptoDashboardTheme(
      priceUpColor: Color.lerp(priceUpColor, other.priceUpColor, t)!,
      priceDownColor: Color.lerp(priceDownColor, other.priceDownColor, t)!,
      priceNeutralColor: Color.lerp(
        priceNeutralColor,
        other.priceNeutralColor,
        t,
      )!,
      volumeSpikeColor: Color.lerp(
        volumeSpikeColor,
        other.volumeSpikeColor,
        t,
      )!,
      connectionStatusColor: Color.lerp(
        connectionStatusColor,
        other.connectionStatusColor,
        t,
      )!,
      cardBorderColor: Color.lerp(cardBorderColor, other.cardBorderColor, t)!,
      shimmerBaseColor: Color.lerp(
        shimmerBaseColor,
        other.shimmerBaseColor,
        t,
      )!,
      shimmerHighlightColor: Color.lerp(
        shimmerHighlightColor,
        other.shimmerHighlightColor,
        t,
      )!,
      successGradient: LinearGradient.lerp(
        successGradient,
        other.successGradient,
        t,
      )!,
      errorGradient: LinearGradient.lerp(
        errorGradient,
        other.errorGradient,
        t,
      )!,
      warningGradient: LinearGradient.lerp(
        warningGradient,
        other.warningGradient,
        t,
      )!,
      neutralGradient: LinearGradient.lerp(
        neutralGradient,
        other.neutralGradient,
        t,
      )!,
      defaultBorderRadius: BorderRadius.lerp(
        defaultBorderRadius,
        other.defaultBorderRadius,
        t,
      )!,
      defaultPadding: EdgeInsets.lerp(defaultPadding, other.defaultPadding, t)!,
      defaultAnimationDuration: Duration(
        milliseconds: lerpDouble(
          defaultAnimationDuration.inMilliseconds,
          other.defaultAnimationDuration.inMilliseconds,
          t,
        )!.round(),
      ),
    );
  }

  /// Helper method to get theme extension from BuildContext
  static CryptoDashboardTheme of(BuildContext context) {
    return Theme.of(context).extension<CryptoDashboardTheme>()!;
  }

  /// Helper method to get price color based on change value
  Color getPriceChangeColor(double change) {
    if (change > 0) return priceUpColor;
    if (change < 0) return priceDownColor;
    return priceNeutralColor;
  }

  /// Helper method to get price change gradient
  LinearGradient getPriceChangeGradient(double change) {
    if (change > 0) return successGradient;
    if (change < 0) return errorGradient;
    return neutralGradient;
  }

  /// Helper method to create shimmer gradient
  LinearGradient createShimmerGradient() {
    return LinearGradient(
      colors: [shimmerBaseColor, shimmerHighlightColor, shimmerBaseColor],
      stops: const [0.0, 0.5, 1.0],
      begin: const Alignment(-1.0, 0.0),
      end: const Alignment(1.0, 0.0),
    );
  }
}

/// Helper method to get double value for lerping
double? lerpDouble(num? a, num? b, double t) {
  if (a == null && b == null) return null;
  a ??= 0.0;
  b ??= 0.0;
  return a + (b - a) * t;
}
