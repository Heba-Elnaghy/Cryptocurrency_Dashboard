import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import '../../domain/entities/entities.dart';

/// Accessibility helpers for the crypto dashboard
class AccessibilityHelpers {
  /// Creates semantic labels for cryptocurrency data
  static String createCryptoSemanticLabel(Cryptocurrency crypto) {
    final priceChange = crypto.priceChange24h;
    final changeDirection = priceChange >= 0 ? 'increased' : 'decreased';
    final changePercent = priceChange.abs().toStringAsFixed(2);
    
    String label = '${crypto.name}, symbol ${crypto.symbol}, '
        'current price ${crypto.price.toStringAsFixed(2)} dollars, '
        'price has $changeDirection by $changePercent percent in the last 24 hours';
    
    if (crypto.hasVolumeSpike) {
      label += ', volume spike detected';
    }
    
    if (crypto.status == ListingStatus.delisted) {
      label += ', delisted cryptocurrency';
    }
    
    return label;
  }

  /// Creates semantic labels for connection status
  static String createConnectionSemanticLabel(ConnectionStatus status) {
    if (status.isConnected) {
      return 'Connected to real-time data feed, last updated ${_formatTime(status.lastUpdate)}';
    } else {
      return 'Disconnected from real-time data feed, ${status.statusMessage}';
    }
  }

  /// Creates semantic labels for volume alerts
  static String createVolumeAlertSemanticLabel(VolumeAlert alert) {
    return 'Volume alert for ${alert.symbol}, '
        'volume increased by ${alert.spikePercentage.toStringAsFixed(1)} percent, '
        'current volume ${alert.currentVolume.toStringAsFixed(0)}';
  }

  /// Wraps a widget with proper semantics for screen readers
  static Widget withSemantics({
    required Widget child,
    required String label,
    String? hint,
    bool? button,
    bool? header,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: button ?? false,
      header: header ?? false,
      onTap: onTap,
      child: child,
    );
  }

  /// Creates accessible button with proper semantics
  static Widget accessibleButton({
    required Widget child,
    required String semanticLabel,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      child: child,
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: true,
      child: button,
    );
  }

  /// Creates accessible card with proper focus handling
  static Widget accessibleCard({
    required Widget child,
    required String semanticLabel,
    VoidCallback? onTap,
    Color? focusColor,
  }) {
    return Focus(
      child: Builder(
        builder: (context) {
          final focusNode = Focus.of(context);
          return Card(
            color: focusNode.hasFocus ? (focusColor ?? Theme.of(context).focusColor) : null,
            child: InkWell(
              onTap: onTap,
              child: Semantics(
                label: semanticLabel,
                button: onTap != null,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Announces important updates to screen readers
  static void announceUpdate(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Creates accessible loading indicator
  static Widget accessibleLoadingIndicator({
    String? label,
    double? value,
  }) {
    return Semantics(
      label: label ?? 'Loading cryptocurrency data',
      liveRegion: true,
      child: CircularProgressIndicator(
        value: value,
        semanticsLabel: label ?? 'Loading',
      ),
    );
  }

  /// Creates accessible error widget
  static Widget accessibleErrorWidget({
    required String error,
    VoidCallback? onRetry,
  }) {
    return Semantics(
      label: 'Error: $error',
      liveRegion: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            semanticLabel: 'Error icon',
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            accessibleButton(
              semanticLabel: 'Retry loading data',
              onPressed: onRetry,
              tooltip: 'Tap to retry loading cryptocurrency data',
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  /// Formats time for accessibility
  static String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

   /// Checks if high contrast mode is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Gets appropriate text scale factor
  static double getTextScaleFactor(BuildContext context) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    // Clamp between reasonable bounds
    return textScaleFactor.clamp(0.8, 2.0);
  }

  /// Creates accessible text with proper scaling
  static Widget accessibleText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Builder(
      builder: (context) {
        final scaleFactor = getTextScaleFactor(context);
        final adjustedStyle = style?.copyWith(
          fontSize: (style.fontSize ?? 14) * scaleFactor,
        );

        return Text(
          text,
          style: adjustedStyle,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          textScaleFactor: 1.0, // We handle scaling manually
        );
      },
    );
  }


}

/// Provides high contrast colors for accessibility
class AccessibleColors {
  static const Color highContrastText = Colors.black;
  static const Color highContrastBackground = Colors.white;
  static const Color focusColor = Color(0xFF2196F3);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);
}

 