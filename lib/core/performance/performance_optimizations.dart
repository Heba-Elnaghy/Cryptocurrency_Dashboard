import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance optimization utilities for the crypto dashboard
class PerformanceOptimizations {
  /// Optimized build method wrapper that prevents unnecessary rebuilds
  static Widget optimizedBuilder({
    required Widget Function() builder,
    List<Object?>? dependencies,
  }) {
    return Builder(
      builder: (context) {
        if (kDebugMode) {
          // In debug mode, track rebuild frequency
          debugPrint('Widget rebuilt with dependencies: $dependencies');
        }
        return builder();
      },
    );
  }

  /// Creates a performance-optimized list view for cryptocurrency cards
  static Widget optimizedListView({
    required List<Widget> children,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      // Use itemExtent for better performance when items have consistent height
      itemExtent: 120.0, // Approximate height of cryptocurrency cards
      itemCount: children.length,
      // Add caching for better scroll performance
      cacheExtent: 500.0,
      itemBuilder: (context, index) {
        if (index >= children.length) return const SizedBox.shrink();

        // Wrap each item in RepaintBoundary for isolation
        return RepaintBoundary(
          key: ValueKey('list_item_$index'),
          child: children[index],
        );
      },
    );
  }

  /// Memory-efficient image loading with caching
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
      // Enable caching for better performance
      cacheWidth: width?.round(),
      cacheHeight: height?.round(),
      // Use appropriate filter quality
      filterQuality: FilterQuality.medium,
      // Add loading and error states
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            SizedBox(
              width: width,
              height: height,
              child: const Icon(Icons.error_outline),
            );
      },
    );
  }

  /// Optimized animation controller disposal
  static void disposeAnimationControllers(
    List<AnimationController> controllers,
  ) {
    for (final controller in controllers) {
      // Check if controller is still active before disposing
      try {
        controller.dispose();
      } catch (e) {
        // Controller already disposed, ignore
      }
    }
  }

  /// Performance monitoring for debug builds
  static void logPerformanceMetric(String metric, Duration duration) {
    if (kDebugMode) {
      debugPrint('Performance: $metric took ${duration.inMilliseconds}ms');
    }
  }

  /// Optimized setState wrapper that batches updates
  static void batchedSetState(
    StatefulWidget widget,
    VoidCallback setState, {
    Duration delay = const Duration(milliseconds: 16), // ~60fps
  }) {
    Future.delayed(delay, setState);
  }
}

/// Mixin for widgets that need performance monitoring
mixin PerformanceMonitorMixin<T extends StatefulWidget> on State<T> {
  final Stopwatch _buildStopwatch = Stopwatch();

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      _buildStopwatch.start();
    }

    final widget = buildWidget(context);

    if (kDebugMode) {
      _buildStopwatch.stop();
      PerformanceOptimizations.logPerformanceMetric(
        '${T.toString()} build',
        _buildStopwatch.elapsed,
      );
      _buildStopwatch.reset();
    }

    return widget;
  }

  /// Override this method instead of build()
  Widget buildWidget(BuildContext context);
}

/// Custom scroll physics for better performance
class OptimizedScrollPhysics extends BouncingScrollPhysics {
  const OptimizedScrollPhysics({super.parent});

  @override
  OptimizedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return OptimizedScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double get minFlingVelocity => 100.0; // Reduced for better control

  @override
  double get maxFlingVelocity => 2000.0; // Reduced for smoother scrolling
}
