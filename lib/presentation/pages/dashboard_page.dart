import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc.dart';
import '../widgets/widgets.dart';
import '../../core/network/network.dart';
import '../../core/utils/performance_monitor.dart';
import '../../core/accessibility/accessibility_helpers.dart';
import '../../injection_container.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Enable performance monitoring in debug mode
    assert(() {
      PerformanceMonitor.enable();
      RebuildTracker.enable();
      return true;
    }());

    // Load initial data when the page is created
    context.read<CryptocurrencyBloc>().add(const LoadInitialData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes for connection management and resource cleanup
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - start updates
        context.read<CryptocurrencyBloc>().add(const AppLifecycleChanged(true));
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App went to background or is being terminated - stop updates and cleanup
        context.read<CryptocurrencyBloc>().add(
          const AppLifecycleChanged(false),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the entire page with offline indicator for enhanced network error handling
    return OfflineIndicator(
      offlineManager: sl<OfflineManager>(),
      offlineDetector: sl<OfflineDetector>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Crypto Dashboard'),
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          actions: [
            // Connection status indicator with highly selective rebuilds
            ConnectionStatusBuilder(
              debugName: 'AppBarConnectionStatus',
              builder: (context, state) {
                return AnimatedConnectionStatus(
                  connectionStatus: state.connectionStatus,
                  textStyle: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: BlocBuilder<CryptocurrencyBloc, CryptocurrencyState>(
          buildWhen: (previous, current) {
            // Only rebuild for state type changes or significant data changes
            if (previous.runtimeType != current.runtimeType) {
              return true;
            }

            if (previous is CryptocurrencyLoaded &&
                current is CryptocurrencyLoaded) {
              return _shouldRebuildBody(previous, current);
            }

            return false;
          },
          builder: (context, state) {
            return PerformanceMonitor.measure(
              'DashboardBody Build',
              () {
                return _buildBody(context, state);
              },
              metadata: {
                'stateType': state.runtimeType.toString(),
                'cryptoCount': state is CryptocurrencyLoaded
                    ? state.cryptocurrencies.length
                    : 0,
              },
            );
          },
        ),
      ),
    );
  }

  /// Determines if the body should rebuild based on state changes
  bool _shouldRebuildBody(
    CryptocurrencyLoaded previous,
    CryptocurrencyLoaded current,
  ) {
    // Rebuild if cryptocurrencies list length changed
    if (previous.cryptocurrencies.length != current.cryptocurrencies.length) {
      return true;
    }

    // Rebuild if refresh state changed
    if (previous.isRefreshing != current.isRefreshing) {
      return true;
    }

    // Rebuild if alerts changed significantly
    if (previous.activeAlerts.length != current.activeAlerts.length) {
      return true;
    }

    // Check for significant cryptocurrency data changes
    for (
      int i = 0;
      i < previous.cryptocurrencies.length &&
          i < current.cryptocurrencies.length;
      i++
    ) {
      final prev = previous.cryptocurrencies[i];
      final curr = current.cryptocurrencies[i];

      // Check for significant changes that warrant a rebuild
      if (prev.symbol != curr.symbol ||
          (prev.price - curr.price).abs() >
              0.01 || // Only rebuild for price changes > 1 cent
          prev.status != curr.status ||
          prev.hasVolumeSpike != curr.hasVolumeSpike) {
        return true;
      }
    }

    // Check if last updated time changed significantly (more than 1 minute)
    if ((previous.lastUpdated.difference(current.lastUpdated)).inMinutes.abs() >
        1) {
      return true;
    }

    // Don't rebuild for minor changes
    return false;
  }

  Widget _buildBody(BuildContext context, CryptocurrencyState state) {
    if (state is CryptocurrencyInitial || state is CryptocurrencyLoading) {
      return _buildLoadingState(state);
    } else if (state is CryptocurrencyLoaded ||
        state is CryptocurrencyRefreshing) {
      return _buildLoadedState(context, state as CryptocurrencyLoaded);
    } else if (state is CryptocurrencyError) {
      return _buildErrorState(context, state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingState(CryptocurrencyState state) {
    final message = state is CryptocurrencyLoading
        ? state.message ?? 'Loading...'
        : 'Loading...';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AccessibilityHelpers.accessibleLoadingIndicator(
            label: 'Loading cryptocurrency data, please wait',
          ),
          const SizedBox(height: 16),
          AccessibilityHelpers.accessibleText(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, CryptocurrencyLoaded state) {
    // Determine if this is an initial load (first time showing data)
    final isInitialLoad =
        state.cryptocurrencies.isNotEmpty &&
        !state.isRefreshing &&
        state.lastUpdated.difference(DateTime.now()).inSeconds.abs() < 5;

    return EnhancedRefreshIndicator(
      onRefresh: () async {
        context.read<CryptocurrencyBloc>().add(const RefreshData());

        // Wait for refresh to complete
        await context.read<CryptocurrencyBloc>().stream.firstWhere(
          (state) => state is! CryptocurrencyRefreshing,
        );
      },
      child: CustomScrollView(
        slivers: [
          // Last updated info with animation
          SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Last updated: ${_formatLastUpdated(state.lastUpdated)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          if (state.isRefreshing)
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1000),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, rotationValue, child) {
                                return Transform.rotate(
                                  angle: rotationValue * 2 * 3.14159,
                                  child: const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Animated cryptocurrency list
          AnimatedCryptocurrencyList(
            cryptocurrencies: state.cryptocurrencies,
            activeAlerts: state.activeAlerts,
            isInitialLoad: isInitialLoad,
          ),

          // Bottom padding with animation
          SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return SizedBox(height: 16 * value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, CryptocurrencyError state) {
    return AccessibilityHelpers.accessibleErrorWidget(
      error: state.details != null
          ? '${state.message}: ${state.details}'
          : state.message,
      onRetry: state.canRetry
          ? () {
              context.read<CryptocurrencyBloc>().add(const LoadInitialData());
            }
          : null,
    );
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
