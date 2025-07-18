import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';
import '../../core/utils/performance_monitor.dart';
import '../../core/accessibility/accessibility_helpers.dart';
import 'animated_cryptocurrency_card.dart';

class AnimatedCryptocurrencyList extends StatefulWidget {
  final List<Cryptocurrency> cryptocurrencies;
  final Map<String, VolumeAlert> activeAlerts;
  final bool isInitialLoad;
  final VoidCallback? onRefresh;

  const AnimatedCryptocurrencyList({
    super.key,
    required this.cryptocurrencies,
    required this.activeAlerts,
    this.isInitialLoad = false,
    this.onRefresh,
  });

  @override
  State<AnimatedCryptocurrencyList> createState() =>
      _AnimatedCryptocurrencyListState();
}

class _AnimatedCryptocurrencyListState extends State<AnimatedCryptocurrencyList>
    with TickerProviderStateMixin, PerformanceMonitorMixin {
  late AnimationController _staggerController;
  late AnimationController _updateController;
  final List<AnimationController> _itemControllers = [];
  final List<Animation<double>> _itemAnimations = [];
  final List<Animation<Offset>> _itemSlideAnimations = [];
  final List<Animation<double>> _itemScaleAnimations = [];

  // Track which items have been animated to avoid re-animating on updates
  final Set<String> _animatedItems = <String>{};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Main stagger controller for initial load
    _staggerController = AnimationController(
      duration: Duration(
        milliseconds: 100 + (widget.cryptocurrencies.length * 150),
      ),
      vsync: this,
    );

    // Update controller for smooth data updates
    _updateController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _setupItemAnimations();

    // Start staggered animation if this is initial load
    if (widget.isInitialLoad) {
      _startStaggeredAnimation();
    } else {
      // If not initial load, show all items immediately
      _staggerController.value = 1.0;
      for (final controller in _itemControllers) {
        controller.value = 1.0;
      }
    }
  }

  void _setupItemAnimations() {
    // Clear existing controllers
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    _itemControllers.clear();
    _itemAnimations.clear();
    _itemSlideAnimations.clear();
    _itemScaleAnimations.clear();

    // Create individual controllers for each item
    for (int i = 0; i < widget.cryptocurrencies.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );

      // Opacity animation
      final opacityAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

      // Slide animation from bottom
      final slideAnimation =
          Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeOutCubic),
          );

      // Scale animation with bounce
      final scaleAnimation = Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));

      _itemControllers.add(controller);
      _itemAnimations.add(opacityAnimation);
      _itemSlideAnimations.add(slideAnimation);
      _itemScaleAnimations.add(scaleAnimation);
    }
  }

  void _startStaggeredAnimation() {
    _staggerController.forward();

    // Animate each item with a staggered delay
    for (int i = 0; i < _itemControllers.length; i++) {
      final delay = Duration(milliseconds: i * 150);

      Future.delayed(delay, () {
        if (mounted) {
          _itemControllers[i].forward();
          _animatedItems.add(widget.cryptocurrencies[i].symbol);
        }
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedCryptocurrencyList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle list changes
    if (oldWidget.cryptocurrencies.length != widget.cryptocurrencies.length) {
      _setupItemAnimations();

      // Animate new items if they weren't animated before
      for (int i = 0; i < widget.cryptocurrencies.length; i++) {
        final symbol = widget.cryptocurrencies[i].symbol;
        if (!_animatedItems.contains(symbol)) {
          Future.delayed(Duration(milliseconds: i * 100), () {
            if (mounted && i < _itemControllers.length) {
              _itemControllers[i].forward();
              _animatedItems.add(symbol);
            }
          });
        } else {
          // Item already exists, show immediately
          if (i < _itemControllers.length) {
            _itemControllers[i].value = 1.0;
          }
        }
      }
    } else {
      // Handle data updates for existing items
      _handleDataUpdates(oldWidget.cryptocurrencies);
    }
  }

  void _handleDataUpdates(List<Cryptocurrency> oldCryptocurrencies) {
    // Check for significant data changes that warrant animation
    for (
      int i = 0;
      i < widget.cryptocurrencies.length && i < oldCryptocurrencies.length;
      i++
    ) {
      final current = widget.cryptocurrencies[i];
      final previous = oldCryptocurrencies[i];

      // Check if price or volume changed significantly
      final priceChanged = (current.price - previous.price).abs() > 0.01;
      final volumeChanged =
          (current.volume24h - previous.volume24h).abs() >
          previous.volume24h * 0.1;
      final statusChanged = current.status != previous.status;

      if (priceChanged || volumeChanged || statusChanged) {
        // Trigger subtle update animation
        _triggerItemUpdateAnimation(i);
      }
    }
  }

  void _triggerItemUpdateAnimation(int index) {
    if (index < _itemControllers.length && mounted) {
      // Create a subtle pulse effect
      final controller = _itemControllers[index];
      controller.forward().then((_) {
        controller.reverse().then((_) {
          controller.forward();
        });
      });
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _updateController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return measureBuild('AnimatedCryptocurrencyList', () {
      PerformanceMonitor.logEvent(
        'CryptocurrencyList Build',
        data: {
          'itemCount': widget.cryptocurrencies.length,
          'isInitialLoad': widget.isInitialLoad,
          'alertCount': widget.activeAlerts.length,
        },
      );

      return SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index >= widget.cryptocurrencies.length ||
              index >= _itemAnimations.length ||
              index >= _itemSlideAnimations.length ||
              index >= _itemScaleAnimations.length) {
            return const SizedBox.shrink();
          }

          final crypto = widget.cryptocurrencies[index];
          final hasAlert = widget.activeAlerts.containsKey(crypto.symbol);
          final alert = hasAlert ? widget.activeAlerts[crypto.symbol] : null;

          // Use RepaintBoundary to isolate repaints for each card with accessibility
          return RepaintBoundary(
            key: ValueKey('repaint_${crypto.symbol}'),
            child: Semantics(
              label: AccessibilityHelpers.createCryptoSemanticLabel(crypto),
              button: true,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _itemAnimations[index],
                  _itemSlideAnimations[index],
                  _itemScaleAnimations[index],
                ]),
                builder: (context, child) {
                  return RebuildTrackingWidget(
                    name: 'CryptoCard_${crypto.symbol}',
                    child: SlideTransition(
                      position: _itemSlideAnimations[index],
                      child: ScaleTransition(
                        scale: _itemScaleAnimations[index],
                        child: FadeTransition(
                          opacity: _itemAnimations[index],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 4.0,
                            ),
                            child: _OptimizedCryptocurrencyCard(
                              key: ValueKey(crypto.symbol),
                              cryptocurrency: crypto,
                              volumeAlert: alert,
                              animationDelay: Duration(
                                milliseconds: index * 50,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }, childCount: widget.cryptocurrencies.length),
      );
    });
  }
}

/// Optimized cryptocurrency card that only rebuilds when its specific data changes
class _OptimizedCryptocurrencyCard extends StatefulWidget {
  final Cryptocurrency cryptocurrency;
  final VolumeAlert? volumeAlert;
  final Duration animationDelay;

  const _OptimizedCryptocurrencyCard({
    super.key,
    required this.cryptocurrency,
    this.volumeAlert,
    required this.animationDelay,
  });

  @override
  State<_OptimizedCryptocurrencyCard> createState() =>
      _OptimizedCryptocurrencyCardState();
}

class _OptimizedCryptocurrencyCardState
    extends State<_OptimizedCryptocurrencyCard> {
  Cryptocurrency? _previousCrypto;
  VolumeAlert? _previousAlert;

  @override
  void didUpdateWidget(_OptimizedCryptocurrencyCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Track previous values for comparison
    _previousCrypto = oldWidget.cryptocurrency;
    _previousAlert = oldWidget.volumeAlert;
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild the card if there are significant changes
    final shouldAnimate =
        _previousCrypto != null &&
        ((_previousCrypto!.price - widget.cryptocurrency.price).abs() > 0.001 ||
            _previousCrypto!.status != widget.cryptocurrency.status ||
            _previousCrypto!.hasVolumeSpike !=
                widget.cryptocurrency.hasVolumeSpike ||
            (_previousAlert == null) != (widget.volumeAlert == null));

    return AnimatedCryptocurrencyCard(
      cryptocurrency: widget.cryptocurrency,
      volumeAlert: widget.volumeAlert,
      animationDelay: shouldAnimate ? Duration.zero : widget.animationDelay,
    );
  }
}
