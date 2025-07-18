import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc.dart';
import '../../core/utils/performance_monitor.dart';

/// A specialized BlocBuilder that provides highly selective rebuilds
/// for different parts of the cryptocurrency state
class SelectiveCryptocurrencyBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, CryptocurrencyLoaded state)
  builder;
  final bool Function(
    CryptocurrencyLoaded previous,
    CryptocurrencyLoaded current,
  )?
  buildWhen;
  final String? debugName;

  const SelectiveCryptocurrencyBuilder({
    super.key,
    required this.builder,
    this.buildWhen,
    this.debugName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CryptocurrencyBloc, CryptocurrencyState>(
      buildWhen: (previous, current) {
        // Only build when we have loaded states
        if (previous is! CryptocurrencyLoaded ||
            current is! CryptocurrencyLoaded) {
          return previous.runtimeType != current.runtimeType;
        }

        // Use custom buildWhen if provided
        if (buildWhen != null) {
          final shouldBuild = buildWhen!(previous, current);

          // Log rebuild decisions for performance monitoring
          if (debugName != null) {
            PerformanceMonitor.logEvent(
              'SelectiveBuilder: $debugName',
              data: {
                'shouldBuild': shouldBuild,
                'previousHash': previous.hashCode,
                'currentHash': current.hashCode,
              },
            );
          }

          return shouldBuild;
        }

        // Default: use optimized equality check
        return !previous.isEqualTo(current);
      },
      builder: (context, state) {
        if (state is CryptocurrencyLoaded) {
          return builder(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

/// Builder that only rebuilds when cryptocurrency data changes
class CryptocurrencyDataBuilder extends SelectiveCryptocurrencyBuilder {
  CryptocurrencyDataBuilder({
    super.key,
    required super.builder,
    super.debugName = 'CryptocurrencyData',
  }) : super(
         buildWhen: (previous, current) {
           // Only rebuild if cryptocurrency list or individual crypto data changed
           if (previous.cryptocurrencies.length !=
               current.cryptocurrencies.length) {
             return true;
           }

           // Check for significant data changes
           for (
             int i = 0;
             i < previous.cryptocurrencies.length &&
                 i < current.cryptocurrencies.length;
             i++
           ) {
             final prev = previous.cryptocurrencies[i];
             final curr = current.cryptocurrencies[i];

             if (prev.symbol != curr.symbol ||
                 (prev.price - curr.price).abs() > 0.001 ||
                 prev.status != curr.status ||
                 prev.hasVolumeSpike != curr.hasVolumeSpike) {
               return true;
             }
           }

           return false;
         },
       );
}

/// Builder that only rebuilds when connection status changes
class ConnectionStatusBuilder extends SelectiveCryptocurrencyBuilder {
  ConnectionStatusBuilder({
    super.key,
    required super.builder,
    super.debugName = 'ConnectionStatus',
  }) : super(
         buildWhen: (previous, current) {
           return previous.connectionStatus.isConnected !=
                   current.connectionStatus.isConnected ||
               previous.connectionStatus.statusMessage !=
                   current.connectionStatus.statusMessage;
         },
       );
}

/// Builder that only rebuilds when volume alerts change
class VolumeAlertsBuilder extends SelectiveCryptocurrencyBuilder {
  VolumeAlertsBuilder({
    super.key,
    required super.builder,
    super.debugName = 'VolumeAlerts',
  }) : super(
         buildWhen: (previous, current) {
           return previous.activeAlerts.length != current.activeAlerts.length ||
               !_mapEquals(previous.activeAlerts, current.activeAlerts);
         },
       );

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Builder that only rebuilds when refresh state changes
class RefreshStateBuilder extends SelectiveCryptocurrencyBuilder {
  RefreshStateBuilder({
    super.key,
    required super.builder,
    super.debugName = 'RefreshState',
  }) : super(
         buildWhen: (previous, current) {
           return previous.isRefreshing != current.isRefreshing;
         },
       );
}

/// Builder that only rebuilds when last updated time changes significantly
class LastUpdatedBuilder extends SelectiveCryptocurrencyBuilder {
  final Duration threshold;

  LastUpdatedBuilder({
    super.key,
    required super.builder,
    this.threshold = const Duration(minutes: 1),
    super.debugName = 'LastUpdated',
  }) : super(
         buildWhen: (previous, current) {
           return (previous.lastUpdated.difference(current.lastUpdated)).abs() >
               threshold;
         },
       );
}

/// A composite builder that combines multiple selective builders
class CompositeCryptocurrencyBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, CryptocurrencyLoaded state)
  builder;
  final List<
    bool Function(CryptocurrencyLoaded previous, CryptocurrencyLoaded current)
  >
  conditions;
  final String? debugName;

  const CompositeCryptocurrencyBuilder({
    super.key,
    required this.builder,
    required this.conditions,
    this.debugName,
  });

  @override
  Widget build(BuildContext context) {
    return SelectiveCryptocurrencyBuilder(
      debugName: debugName,
      buildWhen: (previous, current) {
        // Rebuild if any condition is true
        for (final condition in conditions) {
          if (condition(previous, current)) {
            return true;
          }
        }
        return false;
      },
      builder: builder,
    );
  }
}

/// Predefined condition functions for common use cases
class BuildConditions {
  /// Condition for price changes above a threshold
  static bool Function(CryptocurrencyLoaded, CryptocurrencyLoaded)
  priceChangeAbove(double threshold) {
    return (previous, current) {
      for (
        int i = 0;
        i < previous.cryptocurrencies.length &&
            i < current.cryptocurrencies.length;
        i++
      ) {
        final prev = previous.cryptocurrencies[i];
        final curr = current.cryptocurrencies[i];
        if ((prev.price - curr.price).abs() > threshold) {
          return true;
        }
      }
      return false;
    };
  }

  /// Condition for volume changes above a percentage
  static bool Function(CryptocurrencyLoaded, CryptocurrencyLoaded)
  volumeChangeAbove(double percentage) {
    return (previous, current) {
      for (
        int i = 0;
        i < previous.cryptocurrencies.length &&
            i < current.cryptocurrencies.length;
        i++
      ) {
        final prev = previous.cryptocurrencies[i];
        final curr = current.cryptocurrencies[i];
        if (prev.volume24h > 0) {
          final change =
              (curr.volume24h - prev.volume24h).abs() / prev.volume24h;
          if (change > percentage) {
            return true;
          }
        }
      }
      return false;
    };
  }

  /// Condition for status changes
  static bool Function(CryptocurrencyLoaded, CryptocurrencyLoaded)
  statusChanged() {
    return (previous, current) {
      for (
        int i = 0;
        i < previous.cryptocurrencies.length &&
            i < current.cryptocurrencies.length;
        i++
      ) {
        if (previous.cryptocurrencies[i].status !=
            current.cryptocurrencies[i].status) {
          return true;
        }
      }
      return false;
    };
  }

  /// Condition for connection status changes
  static bool Function(CryptocurrencyLoaded, CryptocurrencyLoaded)
  connectionStatusChanged() {
    return (previous, current) {
      return previous.connectionStatus.isConnected !=
              current.connectionStatus.isConnected ||
          previous.connectionStatus.statusMessage !=
              current.connectionStatus.statusMessage;
    };
  }

  /// Condition for alert count changes
  static bool Function(CryptocurrencyLoaded, CryptocurrencyLoaded)
  alertCountChanged() {
    return (previous, current) {
      return previous.activeAlerts.length != current.activeAlerts.length;
    };
  }

  /// Condition for refresh state changes
  static bool Function(CryptocurrencyLoaded, CryptocurrencyLoaded)
  refreshStateChanged() {
    return (previous, current) {
      return previous.isRefreshing != current.isRefreshing;
    };
  }

  /// Condition for time-based updates (e.g., every minute)
  static bool Function(CryptocurrencyLoaded, CryptocurrencyLoaded)
  timeBasedUpdate(Duration interval) {
    return (previous, current) {
      return (previous.lastUpdated.difference(current.lastUpdated)).abs() >=
          interval;
    };
  }
}

/// A mixin that provides easy access to selective builders
mixin SelectiveBuilderMixin {
  /// Creates a builder that only rebuilds for cryptocurrency data changes
  Widget buildForCryptocurrencyData(
    Widget Function(BuildContext, CryptocurrencyLoaded) builder,
  ) {
    return CryptocurrencyDataBuilder(builder: builder);
  }

  /// Creates a builder that only rebuilds for connection status changes
  Widget buildForConnectionStatus(
    Widget Function(BuildContext, CryptocurrencyLoaded) builder,
  ) {
    return ConnectionStatusBuilder(builder: builder);
  }

  /// Creates a builder that only rebuilds for volume alert changes
  Widget buildForVolumeAlerts(
    Widget Function(BuildContext, CryptocurrencyLoaded) builder,
  ) {
    return VolumeAlertsBuilder(builder: builder);
  }

  /// Creates a builder that only rebuilds for refresh state changes
  Widget buildForRefreshState(
    Widget Function(BuildContext, CryptocurrencyLoaded) builder,
  ) {
    return RefreshStateBuilder(builder: builder);
  }

  /// Creates a composite builder with multiple conditions
  Widget buildForMultipleConditions(
    Widget Function(BuildContext, CryptocurrencyLoaded) builder,
    List<bool Function(CryptocurrencyLoaded, CryptocurrencyLoaded)>
    conditions, {
    String? debugName,
  }) {
    return CompositeCryptocurrencyBuilder(
      builder: builder,
      conditions: conditions,
      debugName: debugName,
    );
  }
}
