import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Final performance optimizations for the crypto dashboard
class FinalOptimizations {
  /// Optimize API call frequency based on app state
  static Duration getOptimalUpdateInterval({
    required bool isAppInForeground,
    required bool hasActiveUsers,
    required int dataAge,
  }) {
    if (!isAppInForeground) {
      return const Duration(minutes: 5); // Reduce frequency when backgrounded
    }
    
    if (dataAge < 30) {
      return const Duration(seconds: 2); // Fresh data, update frequently
    } else if (dataAge < 120) {
      return const Duration(seconds: 5); // Moderate age, moderate frequency
    } else {
      return const Duration(seconds: 10); // Older data, less frequent updates
    }
  }

  /// Cache management for optimal memory usage
  static void optimizeCache<T>(Map<String, T> cache, int maxSize) {
    if (cache.length > maxSize) {
      final keysToRemove = cache.keys.take(cache.length - maxSize).toList();
      for (final key in keysToRemove) {
        cache.remove(key);
      }
    }
  }

  /// Batch UI updates to prevent excessive rebuilds
  static void batchUIUpdates(VoidCallback updateCallback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      updateCallback();
    });
  }

  /// Optimize animation performance
  static AnimationController createOptimizedController({
    required Duration duration,
    required TickerProvider vsync,
    double? value,
  }) {
    return AnimationController(
      duration: duration,
      vsync: vsync,
      value: value,
    );
  }

  /// Memory-efficient image loading
  static Widget optimizedNetworkImage({
    required String url,
    double? width,
    double? height,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.contain,
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const CircularProgressIndicator();
      },
    );
  }

  /// Optimize list performance with proper keys
  static Key generateOptimalKey(String identifier, int index) {
    return ValueKey('${identifier}_$index');
  }

  /// Debounce rapid updates
  static void debounce({
    required String key,
    required Duration delay,
    required VoidCallback callback,
  }) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, callback);
  }

  static final Map<String, Timer> _debounceTimers = {};

  /// Cleanup resources
  static void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }
}
