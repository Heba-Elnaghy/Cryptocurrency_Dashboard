import 'package:flutter/material.dart';

/// Application color constants for the crypto dashboard
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // ==================== Primary Brand Colors ====================

  /// Primary brand color (Material 3 seed color)
  static const Color primary = Color(0xFF6750A4);

  /// Primary color variants
  static const Color primaryLight = Color(0xFF9A82DB);
  static const Color primaryDark = Color(0xFF4F378B);

  // ==================== Semantic Colors ====================

  /// Success color for positive price changes and gains
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  /// Error color for negative price changes and losses
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);

  /// Warning color for volume alerts and important notifications
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  /// Info color for general information
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // ==================== Connection Status Colors ====================

  /// Connected status color
  static const Color connected = success;

  /// Connecting status color
  static const Color connecting = warning;

  /// Disconnected status color
  static const Color disconnected = error;

  /// Reconnecting status color
  static const Color reconnecting = Color(0xFFFF5722);

  /// Live data streaming color
  static const Color liveData = Color(0xFF00BCD4);

  // ==================== Price Change Colors ====================

  /// Price increase color (bull market)
  static const Color priceUp = success;
  static const Color priceUpLight = Color(0xFFC8E6C9);
  static const Color priceUpDark = Color(0xFF2E7D32);

  /// Price decrease color (bear market)
  static const Color priceDown = error;
  static const Color priceDownLight = Color(0xFFFFCDD2);
  static const Color priceDownDark = Color(0xFFC62828);

  /// Neutral price color (no change)
  static const Color priceNeutral = Color(0xFF9E9E9E);

  // ==================== Volume Alert Colors ====================

  /// Volume spike alert color
  static const Color volumeSpike = warning;
  static const Color volumeSpikeBackground = Color(0xFFFFF3E0);
  static const Color volumeSpikeBorder = Color(0xFFFFCC02);

  /// High volume color
  static const Color highVolume = Color(0xFF795548);
  static const Color lowVolume = Color(0xFFBDBDBD);

  // ==================== Listing Status Colors ====================

  /// Active listing status
  static const Color statusActive = success;

  /// Delisted status
  static const Color statusDelisted = error;

  /// Suspended status
  static const Color statusSuspended = warning;

  /// Under maintenance status
  static const Color statusMaintenance = Color(0xFF607D8B);

  // ==================== UI Element Colors ====================

  /// Card background colors
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF1E1E1E);

  /// Card elevation
  static const double cardElevation = 2.0;

  /// Default border radius
  static const double defaultBorderRadius = 12.0;

  /// Surface colors
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color surfaceVariantDark = Color(0xFF49454F);

  /// Background colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF000000);

  /// Divider colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  /// Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF424242);

  // ==================== Text Colors ====================

  /// Primary text color
  static const Color textPrimary = Color(0xFF212121);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);

  /// Secondary text color
  static const Color textSecondary = Color(0xFF757575);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  /// Disabled text color
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textDisabledDark = Color(0xFF616161);

  /// Hint text color
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textHintDark = Color(0xFF757575);

  // ==================== Shadow Colors ====================

  /// Light shadow color
  static const Color shadowLight = Color(0x1A000000);

  /// Medium shadow color
  static const Color shadowMedium = Color(0x33000000);

  /// Dark shadow color
  static const Color shadowDark = Color(0x4D000000);

  // ==================== Overlay Colors ====================

  /// Loading overlay color
  static const Color loadingOverlay = Color(0x80000000);

  /// Modal overlay color
  static const Color modalOverlay = Color(0x66000000);

  /// Shimmer base color
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // ==================== Gradient Colors ====================

  /// Success gradient colors
  static const List<Color> successGradient = [
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
  ];

  /// Error gradient colors
  static const List<Color> errorGradient = [
    Color(0xFFF44336),
    Color(0xFFFF5722),
  ];

  /// Warning gradient colors
  static const List<Color> warningGradient = [
    Color(0xFFFF9800),
    Color(0xFFFFC107),
  ];

  /// Primary gradient colors
  static const List<Color> primaryGradient = [
    Color(0xFF6750A4),
    Color(0xFF9A82DB),
  ];

  /// Neutral gradient colors
  static const List<Color> neutralGradient = [
    Color(0xFFE0E0E0),
    Color(0xFFF5F5F5),
  ];

  // ==================== Animation Colors ====================

  /// Flash animation colors for price changes
  static const Color flashPositive = Color(0x4D4CAF50);
  static const Color flashNegative = Color(0x4DF44336);

  /// Pulse animation colors
  static const Color pulseColor = Color(0x1A6750A4);

  /// Ripple effect colors
  static const Color rippleLight = Color(0x1A000000);
  static const Color rippleDark = Color(0x1AFFFFFF);

  // ==================== Chart Colors ====================

  /// Chart line colors
  static const List<Color> chartColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFF44336), // Red
    Color(0xFF00BCD4), // Cyan
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];

  /// Grid line color for charts
  static const Color chartGrid = Color(0xFFE0E0E0);
  static const Color chartGridDark = Color(0xFF424242);

  // ==================== Helper Methods ====================

  /// Get color for price change
  static Color getPriceChangeColor(double change) {
    if (change > 0) return priceUp;
    if (change < 0) return priceDown;
    return priceNeutral;
  }

  /// Get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get connection status color
  static Color getConnectionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'connected':
      case 'live':
        return connected;
      case 'connecting':
        return connecting;
      case 'reconnecting':
        return reconnecting;
      case 'disconnected':
      case 'offline':
        return disconnected;
      default:
        return priceNeutral;
    }
  }

  /// Get listing status color
  static Color getListingStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return statusActive;
      case 'delisted':
        return statusDelisted;
      case 'suspended':
        return statusSuspended;
      case 'maintenance':
        return statusMaintenance;
      default:
        return priceNeutral;
    }
  }

  /// Get volume alert color based on spike percentage
  static Color getVolumeAlertColor(double spikePercentage) {
    if (spikePercentage >= 100) return error; // Very high spike
    if (spikePercentage >= 50) return warning; // High spike
    if (spikePercentage >= 25) return info; // Medium spike
    return priceNeutral; // Low spike
  }

  /// Create a color scheme for light theme
  static ColorScheme createLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(primary: primary, error: error, surface: surface);
  }

  /// Create a color scheme for dark theme
  static ColorScheme createDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ).copyWith(primary: primary, error: error, surface: surfaceDark);
  }

  /// Get theme-appropriate text color
  static Color getTextColor(BuildContext context, {bool secondary = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (secondary) {
      return isDark ? textSecondaryDark : textSecondary;
    }
    return isDark ? textPrimaryDark : textPrimary;
  }

  /// Get theme-appropriate surface color
  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? surfaceDark : surface;
  }

  /// Get theme-appropriate border color
  static Color getBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? borderDark : border;
  }

  /// Create gradient for price change
  static LinearGradient createPriceChangeGradient(double change) {
    if (change > 0) {
      return const LinearGradient(
        colors: successGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (change < 0) {
      return const LinearGradient(
        colors: errorGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return const LinearGradient(
        colors: neutralGradient,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  /// Create shimmer gradient
  static LinearGradient createShimmerGradient() {
    return const LinearGradient(
      colors: [shimmerBase, shimmerHighlight, shimmerBase],
      stops: [0.0, 0.5, 1.0],
      begin: Alignment(-1.0, 0.0),
      end: Alignment(1.0, 0.0),
    );
  }

  /// Get color for cryptocurrency symbol
  static Color getCryptoColor(String symbol) {
    final colors = chartColors;
    final index = symbol.hashCode.abs() % colors.length;
    return colors[index];
  }

  /// Validate if color is accessible
  static bool isAccessible(Color foreground, Color background) {
    final luminance1 = foreground.computeLuminance();
    final luminance2 = background.computeLuminance();
    final lighter = luminance1 > luminance2 ? luminance1 : luminance2;
    final darker = luminance1 > luminance2 ? luminance2 : luminance1;
    final ratio = (lighter + 0.05) / (darker + 0.05);
    return ratio >= 4.5; // WCAG AA standard
  }

  /// Get accessible text color for background
  static Color getAccessibleTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? textPrimary : textPrimaryDark;
  }
}
