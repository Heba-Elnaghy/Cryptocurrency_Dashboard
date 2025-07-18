/// Application-wide constants for the crypto dashboard
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ==================== App Information ====================

  /// Application name
  static const String appName = 'Crypto Dashboard';

  /// Application version
  static const String appVersion = '1.0.0';

  /// Application description
  static const String appDescription =
      'Real-time cryptocurrency dashboard with clean architecture';

  // ==================== Update Intervals ====================

  /// Default update interval for real-time data (in seconds)
  static const int defaultUpdateIntervalSeconds = 3;

  /// Minimum update interval (in seconds)
  static const int minUpdateIntervalSeconds = 1;

  /// Maximum update interval (in seconds)
  static const int maxUpdateIntervalSeconds = 60;

  /// Background update interval when app is not in focus (in minutes)
  static const int backgroundUpdateIntervalMinutes = 5;

  // ==================== UI Constants ====================

  /// Default animation duration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  /// Fast animation duration
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);

  /// Slow animation duration
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  /// Default padding
  static const double defaultPadding = 16.0;

  /// Small padding
  static const double smallPadding = 8.0;

  /// Large padding
  static const double largePadding = 24.0;

  /// Default border radius
  static const double defaultBorderRadius = 12.0;

  /// Card elevation
  static const double cardElevation = 2.0;

  // ==================== Performance Constants ====================

  /// Maximum number of cached items
  static const int maxCacheSize = 1000;

  /// Cache expiry duration (in minutes)
  static const int cacheExpiryMinutes = 15;

  /// Maximum retry attempts for network requests
  static const int maxRetryAttempts = 3;

  /// Retry delay multiplier
  static const double retryDelayMultiplier = 2.0;

  /// Base retry delay (in seconds)
  static const int baseRetryDelaySeconds = 1;

  // ==================== Volume Alert Constants ====================

  /// Volume spike threshold percentage
  static const double volumeSpikeThreshold = 50.0;

  /// Minimum volume for spike detection
  static const double minVolumeForSpike = 1000.0;

  /// Volume alert duration (in minutes)
  static const int volumeAlertDurationMinutes = 5;

  // ==================== Price Change Constants ====================

  /// Significant price change threshold percentage
  static const double significantPriceChangeThreshold = 5.0;

  /// Price change animation duration
  static const Duration priceChangeAnimationDuration = Duration(
    milliseconds: 800,
  );

  /// Price flash duration
  static const Duration priceFlashDuration = Duration(milliseconds: 200);

  // ==================== Connection Constants ====================

  /// Connection timeout (in seconds)
  static const int connectionTimeoutSeconds = 30;

  /// Read timeout (in seconds)
  static const int readTimeoutSeconds = 30;

  /// Write timeout (in seconds)
  static const int writeTimeoutSeconds = 30;

  /// Connection retry attempts
  static const int connectionRetryAttempts = 5;

  // ==================== Data Validation Constants ====================

  /// Maximum price value
  static const double maxPriceValue = 1000000.0;

  /// Minimum price value
  static const double minPriceValue = 0.000001;

  /// Maximum volume value
  static const double maxVolumeValue = 1000000000.0;

  /// Price decimal places
  static const int priceDecimalPlaces = 8;

  /// Volume decimal places
  static const int volumeDecimalPlaces = 2;

  // ==================== Error Messages ====================

  /// Generic error message
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';

  /// Network error message
  static const String networkErrorMessage =
      'Network error. Please check your connection.';

  /// No data error message
  static const String noDataErrorMessage = 'No data available at the moment.';

  /// Loading message
  static const String loadingMessage = 'Loading...';

  /// Retry message
  static const String retryMessage = 'Tap to retry';

  // ==================== Feature Flags ====================

  /// Enable debug logging
  static const bool enableDebugLogging = true;

  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = true;

  /// Enable crash reporting
  static const bool enableCrashReporting = false;

  /// Enable analytics
  static const bool enableAnalytics = false;

  // ==================== Storage Keys ====================

  /// Preferences key prefix
  static const String prefsKeyPrefix = 'crypto_dashboard_';

  /// Last update timestamp key
  static const String lastUpdateTimestampKey = '${prefsKeyPrefix}last_update';

  /// User preferences key
  static const String userPreferencesKey = '${prefsKeyPrefix}user_prefs';

  /// Cache key prefix
  static const String cacheKeyPrefix = '${prefsKeyPrefix}cache_';

  // ==================== Helper Methods ====================

  /// Get update interval as Duration
  static Duration get defaultUpdateInterval =>
      Duration(seconds: defaultUpdateIntervalSeconds);

  /// Get background update interval as Duration
  static Duration get backgroundUpdateInterval =>
      Duration(minutes: backgroundUpdateIntervalMinutes);

  /// Get cache expiry as Duration
  static Duration get cacheExpiry => Duration(minutes: cacheExpiryMinutes);

  /// Get volume alert duration as Duration
  static Duration get volumeAlertDuration =>
      Duration(minutes: volumeAlertDurationMinutes);

  /// Get connection timeout as Duration
  static Duration get connectionTimeout =>
      Duration(seconds: connectionTimeoutSeconds);

  /// Get read timeout as Duration
  static Duration get readTimeout => Duration(seconds: readTimeoutSeconds);

  /// Get write timeout as Duration
  static Duration get writeTimeout => Duration(seconds: writeTimeoutSeconds);

  /// Get base retry delay as Duration
  static Duration get baseRetryDelay =>
      Duration(seconds: baseRetryDelaySeconds);

  /// Calculate retry delay for attempt
  static Duration getRetryDelay(int attempt) {
    final delaySeconds =
        (baseRetryDelaySeconds * (retryDelayMultiplier * attempt)).round();
    return Duration(seconds: delaySeconds.clamp(1, 30));
  }

  /// Validate price value
  static bool isValidPrice(double price) {
    return price >= minPriceValue && price <= maxPriceValue;
  }

  /// Validate volume value
  static bool isValidVolume(double volume) {
    return volume >= 0 && volume <= maxVolumeValue;
  }

  /// Format price with appropriate decimal places
  static String formatPrice(double price) {
    if (price >= 1) {
      return price.toStringAsFixed(2);
    } else if (price >= 0.01) {
      return price.toStringAsFixed(4);
    } else {
      return price.toStringAsFixed(priceDecimalPlaces);
    }
  }

  /// Format volume with appropriate decimal places
  static String formatVolume(double volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    } else {
      return volume.toStringAsFixed(volumeDecimalPlaces);
    }
  }

  /// Get cache key for cryptocurrency data
  static String getCacheKey(String symbol) {
    return '${cacheKeyPrefix}crypto_$symbol';
  }

  /// Check if price change is significant
  static bool isSignificantPriceChange(double changePercentage) {
    return changePercentage.abs() >= significantPriceChangeThreshold;
  }

  /// Check if volume spike is detected
  static bool isVolumeSpikeDetected(
    double currentVolume,
    double previousVolume,
  ) {
    if (currentVolume < minVolumeForSpike) return false;

    final changePercentage =
        ((currentVolume - previousVolume) / previousVolume) * 100;
    return changePercentage >= volumeSpikeThreshold;
  }
}
