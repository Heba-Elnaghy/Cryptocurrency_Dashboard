import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A utility class for creating selective BlocBuilder widgets
/// that only rebuild when specific parts of the state change
class SelectiveRebuilder {
  /// Creates a BlocBuilder that only rebuilds when the selected value changes
  static BlocBuilder<B, S> when<B extends BlocBase<S>, S, T>(
    T Function(S state) selector, {
    required Widget Function(BuildContext context, T value) builder,
    bool Function(T previous, T current)? buildWhen,
  }) {
    return BlocBuilder<B, S>(
      buildWhen: (previous, current) {
        final previousValue = selector(previous);
        final currentValue = selector(current);

        if (buildWhen != null) {
          return buildWhen(previousValue, currentValue);
        }

        return previousValue != currentValue;
      },
      builder: (context, state) {
        return builder(context, selector(state));
      },
    );
  }

  /// Creates a BlocBuilder that rebuilds when any of the selected values change
  static BlocBuilder<B, S> whenAny<B extends BlocBase<S>, S>(
    List<dynamic Function(S state)> selectors, {
    required Widget Function(BuildContext context, S state) builder,
  }) {
    return BlocBuilder<B, S>(
      buildWhen: (previous, current) {
        for (final selector in selectors) {
          if (selector(previous) != selector(current)) {
            return true;
          }
        }
        return false;
      },
      builder: builder,
    );
  }

  /// Creates a BlocBuilder that rebuilds when all of the selected values change
  static BlocBuilder<B, S> whenAll<B extends BlocBase<S>, S>(
    List<dynamic Function(S state)> selectors, {
    required Widget Function(BuildContext context, S state) builder,
  }) {
    return BlocBuilder<B, S>(
      buildWhen: (previous, current) {
        for (final selector in selectors) {
          if (selector(previous) == selector(current)) {
            return false;
          }
        }
        return true;
      },
      builder: builder,
    );
  }

  /// Creates a BlocBuilder that rebuilds based on a custom condition
  static BlocBuilder<B, S> whenCondition<B extends BlocBase<S>, S>(
    bool Function(S previous, S current) condition, {
    required Widget Function(BuildContext context, S state) builder,
  }) {
    return BlocBuilder<B, S>(buildWhen: condition, builder: builder);
  }
}

/// A mixin that provides selective state comparison utilities
mixin SelectiveStateMixin<T> {
  /// Compares two states and returns true if they are different
  /// based on the provided selectors
  bool hasChanged(T previous, T current, List<dynamic Function(T)> selectors) {
    for (final selector in selectors) {
      if (selector(previous) != selector(current)) {
        return true;
      }
    }
    return false;
  }

  /// Compares a specific field between two states
  bool fieldChanged<F>(T previous, T current, F Function(T) selector) {
    return selector(previous) != selector(current);
  }

  /// Compares multiple fields and returns which ones changed
  Map<String, bool> getChangedFields(
    T previous,
    T current,
    Map<String, dynamic Function(T)> fieldSelectors,
  ) {
    final changes = <String, bool>{};

    for (final entry in fieldSelectors.entries) {
      changes[entry.key] = entry.value(previous) != entry.value(current);
    }

    return changes;
  }
}

/// A widget that provides optimized rebuilding for specific state changes
class OptimizedBlocBuilder<B extends BlocBase<S>, S> extends StatefulWidget {
  final Widget Function(BuildContext context, S state) builder;
  final bool Function(S previous, S current)? buildWhen;
  final List<dynamic Function(S)>? selectors;
  final Duration? debounceDelay;

  const OptimizedBlocBuilder({
    super.key,
    required this.builder,
    this.buildWhen,
    this.selectors,
    this.debounceDelay,
  });

  @override
  State<OptimizedBlocBuilder<B, S>> createState() =>
      _OptimizedBlocBuilderState<B, S>();
}

class _OptimizedBlocBuilderState<B extends BlocBase<S>, S>
    extends State<OptimizedBlocBuilder<B, S>> {
  Timer? _debounceTimer;
  S? _lastState;
  bool _shouldRebuild = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool _shouldBuild(S previous, S current) {
    // Use custom buildWhen if provided
    if (widget.buildWhen != null) {
      return widget.buildWhen!(previous, current);
    }

    // Use selectors if provided
    if (widget.selectors != null) {
      for (final selector in widget.selectors!) {
        if (selector(previous) != selector(current)) {
          return true;
        }
      }
      return false;
    }

    // Default comparison
    return previous != current;
  }

  void _handleStateChange(S state) {
    if (_lastState != null && !_shouldBuild(_lastState!, state)) {
      return;
    }

    if (widget.debounceDelay != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(widget.debounceDelay!, () {
        if (mounted) {
          setState(() {
            _shouldRebuild = true;
          });
        }
      });
    } else {
      setState(() {
        _shouldRebuild = true;
      });
    }

    _lastState = state;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<B, S>(
      buildWhen: (previous, current) {
        _handleStateChange(current);
        return _shouldRebuild;
      },
      builder: (context, state) {
        _shouldRebuild = false;
        return widget.builder(context, state);
      },
    );
  }
}

/// Extension methods for BlocBuilder to add selective rebuilding capabilities
extension BlocBuilderExtensions<B extends BlocBase<S>, S> on BlocBuilder<B, S> {
  /// Creates a new BlocBuilder with debounced rebuilds
  BlocBuilder<B, S> debounced(Duration delay) {
    return BlocBuilder<B, S>(
      buildWhen: buildWhen,
      builder: (context, state) {
        // This is a simplified version - in practice, you'd need to implement
        // proper debouncing logic similar to OptimizedBlocBuilder
        return builder(context, state);
      },
    );
  }
}
