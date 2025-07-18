import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';

/// A utility class for monitoring performance of state updates and rebuilds
class PerformanceMonitor {
  static final Map<String, _PerformanceMetric> _metrics = {};
  static bool _isEnabled = false;

  /// Enables performance monitoring (should only be used in debug mode)
  static void enable() {
    _isEnabled = true;
  }

  /// Disables performance monitoring
  static void disable() {
    _isEnabled = false;
  }

  /// Starts timing an operation
  static void startTimer(String operationName) {
    if (!_isEnabled) return;

    _metrics[operationName] = _PerformanceMetric(
      name: operationName,
      startTime: DateTime.now(),
    );
  }

  /// Ends timing an operation and logs the result
  static void endTimer(String operationName, {Map<String, dynamic>? metadata}) {
    if (!_isEnabled) return;

    final metric = _metrics[operationName];
    if (metric == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(metric.startTime);

    metric.endTime = endTime;
    metric.duration = duration;
    metric.metadata = metadata ?? {};

    // Log performance data
    developer.log(
      'Performance: $operationName took ${duration.inMilliseconds}ms',
      name: 'PerformanceMonitor',
      time: endTime,
    );

    // Log metadata if provided
    if (metadata != null && metadata.isNotEmpty) {
      developer.log(
        'Metadata: ${metadata.toString()}',
        name: 'PerformanceMonitor',
      );
    }
  }

  /// Measures the execution time of a function
  static T measure<T>(
    String operationName,
    T Function() operation, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_isEnabled) {
      return operation();
    }

    startTimer(operationName);
    try {
      final result = operation();
      endTimer(operationName, metadata: metadata);
      return result;
    } catch (e) {
      endTimer(operationName, metadata: {...?metadata, 'error': e.toString()});
      rethrow;
    }
  }

  /// Measures the execution time of an async function
  static Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
  }) async {
    if (!_isEnabled) {
      return await operation();
    }

    startTimer(operationName);
    try {
      final result = await operation();
      endTimer(operationName, metadata: metadata);
      return result;
    } catch (e) {
      endTimer(operationName, metadata: {...?metadata, 'error': e.toString()});
      rethrow;
    }
  }

  /// Gets performance metrics for an operation
  static _PerformanceMetric? getMetric(String operationName) {
    return _metrics[operationName];
  }

  /// Gets all performance metrics
  static Map<String, _PerformanceMetric> getAllMetrics() {
    return Map.unmodifiable(_metrics);
  }

  /// Clears all performance metrics
  static void clearMetrics() {
    _metrics.clear();
  }

  /// Logs a custom performance event
  static void logEvent(String eventName, {Map<String, dynamic>? data}) {
    if (!_isEnabled) return;

    developer.log(
      'Event: $eventName',
      name: 'PerformanceMonitor',
      time: DateTime.now(),
    );

    if (data != null && data.isNotEmpty) {
      developer.log('Data: ${data.toString()}', name: 'PerformanceMonitor');
    }
  }
}

/// Internal class to store performance metrics
class _PerformanceMetric {
  final String name;
  final DateTime startTime;
  DateTime? endTime;
  Duration? duration;
  Map<String, dynamic> metadata = {};

  _PerformanceMetric({required this.name, required this.startTime});

  @override
  String toString() {
    return 'PerformanceMetric(name: $name, duration: ${duration?.inMilliseconds}ms, metadata: $metadata)';
  }
}

/// A mixin that provides performance monitoring capabilities to widgets
mixin PerformanceMonitorMixin {
  /// Measures widget build performance
  Widget measureBuild(String widgetName, Widget Function() builder) {
    return PerformanceMonitor.measure(
      'Widget Build: $widgetName',
      builder,
      metadata: {'widget': widgetName},
    );
  }

  /// Measures state update performance
  void measureStateUpdate(String stateName, void Function() updater) {
    PerformanceMonitor.measure(
      'State Update: $stateName',
      updater,
      metadata: {'state': stateName},
    );
  }
}

/// A utility for tracking rebuild frequency
class RebuildTracker {
  static final Map<String, int> _rebuildCounts = {};
  static final Map<String, DateTime> _lastRebuildTimes = {};
  static bool _isEnabled = false;

  /// Enables rebuild tracking
  static void enable() {
    _isEnabled = true;
  }

  /// Disables rebuild tracking
  static void disable() {
    _isEnabled = false;
  }

  /// Records a rebuild for a widget
  static void recordRebuild(String widgetName) {
    if (!_isEnabled) return;

    final now = DateTime.now();
    _rebuildCounts[widgetName] = (_rebuildCounts[widgetName] ?? 0) + 1;
    _lastRebuildTimes[widgetName] = now;

    // Log excessive rebuilds
    final count = _rebuildCounts[widgetName]!;
    if (count % 10 == 0) {
      developer.log(
        'Widget $widgetName has rebuilt $count times',
        name: 'RebuildTracker',
      );
    }
  }

  /// Gets rebuild count for a widget
  static int getRebuildCount(String widgetName) {
    return _rebuildCounts[widgetName] ?? 0;
  }

  /// Gets all rebuild counts
  static Map<String, int> getAllRebuildCounts() {
    return Map.unmodifiable(_rebuildCounts);
  }

  /// Clears rebuild tracking data
  static void clear() {
    _rebuildCounts.clear();
    _lastRebuildTimes.clear();
  }

  /// Gets widgets with excessive rebuilds
  static List<String> getExcessiveRebuilders({int threshold = 50}) {
    return _rebuildCounts.entries
        .where((entry) => entry.value > threshold)
        .map((entry) => entry.key)
        .toList();
  }
}

/// A widget that tracks its own rebuilds
class RebuildTrackingWidget extends StatelessWidget {
  final String name;
  final Widget child;

  const RebuildTrackingWidget({
    super.key,
    required this.name,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    RebuildTracker.recordRebuild(name);
    return child;
  }
}
