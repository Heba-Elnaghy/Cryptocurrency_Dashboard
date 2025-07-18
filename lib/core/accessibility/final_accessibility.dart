import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Final accessibility improvements for the crypto dashboard
class FinalAccessibility {
  /// Enhanced semantic labels for cryptocurrency data
  static String generateCryptoSemanticLabel({
    required String name,
    required String symbol,
    required double price,
    required double change,
    required bool hasVolumeSpike,
    required String status,
  }) {
    final changeDirection = change >= 0 ? 'increased' : 'decreased';
    final changePercent = change.abs().toStringAsFixed(2);

    String label =
        '$name, $symbol, current price \$${price.toStringAsFixed(2)}, '
        'price has $changeDirection by $changePercent percent';

    if (hasVolumeSpike) {
      label += ', volume spike alert active';
    }

    if (status != 'active') {
      label += ', status: $status';
    }

    return label;
  }

  /// Accessible loading indicator with proper semantics
  static Widget accessibleLoadingIndicator({
    required String label,
    Color? color,
    double? size,
  }) {
    return Semantics(
      label: label,
      child: SizedBox(
        width: size ?? 24,
        height: size ?? 24,
        child: CircularProgressIndicator(color: color, strokeWidth: 2),
      ),
    );
  }

  /// Enhanced error widget with accessibility
  static Widget accessibleErrorWidget({
    required String error,
    VoidCallback? onRetry,
    IconData? icon,
  }) {
    return Semantics(
      label: 'Error: $error',
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              Semantics(
                label: 'Retry loading data',
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Accessible connection status indicator
  static Widget accessibleConnectionStatus({
    required bool isConnected,
    required String statusText,
  }) {
    final semanticLabel = isConnected
        ? 'Connected to live data feed'
        : 'Disconnected from live data feed, $statusText';

    return Semantics(
      label: semanticLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 4),
          Text(statusText, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// Accessible volume alert badge
  static Widget accessibleVolumeAlert({
    required double spikePercentage,
    VoidCallback? onDismiss,
  }) {
    final semanticLabel =
        'Volume spike alert: ${spikePercentage.toStringAsFixed(1)}% increase';

    return Semantics(
      label: semanticLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_up, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'Volume spike: +${spikePercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (onDismiss != null) ...[
              const SizedBox(width: 4),
              Semantics(
                label: 'Dismiss volume alert',
                child: GestureDetector(
                  onTap: onDismiss,
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// High contrast theme for accessibility
  static ThemeData createHighContrastTheme({required bool isDark}) {
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();

    return baseTheme.copyWith(
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
              error: Colors.red,
              onError: Colors.white,
            )
          : const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
              error: Colors.red,
              onError: Colors.white,
            ),
      textTheme: baseTheme.textTheme.copyWith(
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  /// Focus management for keyboard navigation
  static void manageFocus({
    required BuildContext context,
    required FocusNode currentFocus,
    required List<FocusNode> focusNodes,
    required bool moveNext,
  }) {
    final currentIndex = focusNodes.indexOf(currentFocus);
    if (currentIndex == -1) return;

    final nextIndex = moveNext
        ? (currentIndex + 1) % focusNodes.length
        : (currentIndex - 1 + focusNodes.length) % focusNodes.length;

    focusNodes[nextIndex].requestFocus();
  }

  /// Screen reader announcements
  static void announceToScreenReader({
    required BuildContext context,
    required String message,
  }) {
    SemanticsService.announce(message, TextDirection.ltr);
  }
}
