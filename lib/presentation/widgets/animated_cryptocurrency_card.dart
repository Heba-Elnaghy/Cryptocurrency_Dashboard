import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/entities.dart';
import '../bloc/bloc.dart';
import 'animated_price_display.dart';
import '../../core/constants/constants.dart';

class AnimatedCryptocurrencyCard extends StatefulWidget {
  final Cryptocurrency cryptocurrency;
  final VolumeAlert? volumeAlert;
  final Duration animationDelay;

  const AnimatedCryptocurrencyCard({
    super.key,
    required this.cryptocurrency,
    this.volumeAlert,
    this.animationDelay = Duration.zero,
  });

  @override
  State<AnimatedCryptocurrencyCard> createState() =>
      _AnimatedCryptocurrencyCardState();
}

class _AnimatedCryptocurrencyCardState extends State<AnimatedCryptocurrencyCard>
    with TickerProviderStateMixin {
  late AnimationController _updateController;
  late AnimationController _alertController;
  late AnimationController _statusController;
  late AnimationController _shimmerController;

  late Animation<double> _updateAnimation;
  late Animation<double> _alertSlideAnimation;
  late Animation<double> _alertOpacityAnimation;
  late Animation<Color?> _statusColorAnimation;
  late Animation<double> _cardElevationAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;

  Cryptocurrency? _previousCrypto;
  VolumeAlert? _previousAlert;
  bool _hasSignificantUpdate = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _previousCrypto = widget.cryptocurrency;
    _previousAlert = widget.volumeAlert;
  }

  void _initializeAnimations() {
    // Update animation for when crypto data changes
    _updateController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Alert animation for volume alerts
    _alertController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Status animation for listing status changes
    _statusController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Shimmer animation for significant updates
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Update animation - subtle scale and glow effect
    _updateAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _updateController, curve: Curves.easeInOut),
    );

    // Alert slide animation
    _alertSlideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _alertController, curve: Curves.elasticOut),
    );

    // Alert opacity animation
    _alertOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _alertController, curve: Curves.easeIn));

    // Card elevation animation for updates
    _cardElevationAnimation = Tween<double>(begin: 2.0, end: 8.0).animate(
      CurvedAnimation(parent: _updateController, curve: Curves.easeInOut),
    );

    // Status color animation
    _statusColorAnimation =
        ColorTween(
          begin: Colors.transparent,
          end: AppColors.withOpacity(AppColors.warning, 0.1),
        ).animate(
          CurvedAnimation(parent: _statusController, curve: Curves.easeInOut),
        );

    // Shimmer animation for significant updates
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Pulse animation for updates
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _updateController, curve: Curves.easeInOut),
    );

    // Start alert animation if alert exists
    if (widget.volumeAlert != null) {
      Future.delayed(widget.animationDelay, () {
        if (mounted) {
          _alertController.forward();
        }
      });
    }
  }

  @override
  void didUpdateWidget(AnimatedCryptocurrencyCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check for cryptocurrency data changes
    if (_previousCrypto != null) {
      final hasDataChanged =
          _previousCrypto!.price != widget.cryptocurrency.price ||
          _previousCrypto!.priceChange24h !=
              widget.cryptocurrency.priceChange24h ||
          _previousCrypto!.volume24h != widget.cryptocurrency.volume24h ||
          _previousCrypto!.status != widget.cryptocurrency.status;

      if (hasDataChanged) {
        _triggerUpdateAnimation();
      }

      // Check for status changes
      if (_previousCrypto!.status != widget.cryptocurrency.status) {
        _triggerStatusAnimation();
      }
    }

    // Check for alert changes
    if (_previousAlert != widget.volumeAlert) {
      if (widget.volumeAlert != null && _previousAlert == null) {
        // New alert appeared
        _alertController.reset();
        _alertController.forward();
      } else if (widget.volumeAlert == null && _previousAlert != null) {
        // Alert disappeared
        _alertController.reverse();
      }
    }

    _previousCrypto = widget.cryptocurrency;
    _previousAlert = widget.volumeAlert;
  }

  void _triggerUpdateAnimation() {
    // Check if this is a significant update (price change > 5% or volume spike)
    if (_previousCrypto != null) {
      final priceChangePercent =
          (_previousCrypto!.price - widget.cryptocurrency.price).abs() /
          _previousCrypto!.price;
      final volumeChangePercent =
          (_previousCrypto!.volume24h - widget.cryptocurrency.volume24h).abs() /
          _previousCrypto!.volume24h;

      _hasSignificantUpdate =
          priceChangePercent > 0.05 || volumeChangePercent > 0.5;

      if (_hasSignificantUpdate) {
        // Trigger shimmer for significant updates
        _shimmerController.forward().then((_) {
          _shimmerController.reverse();
        });
      }
    }

    _updateController.forward().then((_) {
      _updateController.reverse();
    });
  }

  void _triggerStatusAnimation() {
    _statusController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _statusController.reverse();
        }
      });
    });
  }

  @override
  void dispose() {
    _updateController.dispose();
    _alertController.dispose();
    _statusController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _updateAnimation,
        _alertSlideAnimation,
        _alertOpacityAnimation,
        _statusColorAnimation,
        _cardElevationAnimation,
        _shimmerAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _updateAnimation.value * _pulseAnimation.value,
          child: Card(
            elevation: _cardElevationAnimation.value,
            margin: EdgeInsets.zero,
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _statusColorAnimation.value,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Cryptocurrency info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          style:
                                              theme.textTheme.titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        widget
                                                                .cryptocurrency
                                                                .status !=
                                                            ListingStatus.active
                                                        ? theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withValues(
                                                                alpha: 0.6,
                                                              )
                                                        : theme
                                                              .colorScheme
                                                              .onSurface,
                                                  ) ??
                                              const TextStyle(),
                                          child: Text(
                                            widget.cryptocurrency.symbol,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (widget.cryptocurrency.status !=
                                          ListingStatus.active)
                                        Flexible(
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  widget
                                                          .cryptocurrency
                                                          .status ==
                                                      ListingStatus.delisted
                                                  ? AppColors.withOpacity(
                                                      AppColors.statusDelisted,
                                                      0.1,
                                                    )
                                                  : AppColors.withOpacity(
                                                      AppColors.statusSuspended,
                                                      0.1,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    widget
                                                            .cryptocurrency
                                                            .status ==
                                                        ListingStatus.delisted
                                                    ? AppColors.statusDelisted
                                                    : AppColors.statusSuspended,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              widget.cryptocurrency.status ==
                                                      ListingStatus.delisted
                                                  ? 'Delisted'
                                                  : 'Suspended',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        widget
                                                                .cryptocurrency
                                                                .status ==
                                                            ListingStatus
                                                                .delisted
                                                        ? AppColors
                                                              .statusDelisted
                                                        : AppColors
                                                              .statusSuspended,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.onSurface
                                              .withValues(
                                                alpha:
                                                    widget
                                                            .cryptocurrency
                                                            .status !=
                                                        ListingStatus.active
                                                    ? 0.4
                                                    : 0.7,
                                              ),
                                        ) ??
                                        const TextStyle(),
                                    child: Text(widget.cryptocurrency.name),
                                  ),
                                ],
                              ),
                            ),

                            // Animated price info
                            Flexible(
                              child: AnimatedPriceDisplay(
                                price: widget.cryptocurrency.price,
                                priceChange:
                                    widget.cryptocurrency.priceChange24h,
                                priceStyle: theme.textTheme.titleLarge,
                                changeStyle: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),

                        // Animated volume alert
                        if (widget.volumeAlert != null)
                          ClipRect(
                            child: AnimatedBuilder(
                              animation: _alertSlideAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    50 * _alertSlideAnimation.value,
                                  ),
                                  child: Opacity(
                                    opacity: _alertOpacityAnimation.value,
                                    child: Container(
                                      margin: const EdgeInsets.only(top: 12),
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.volumeSpikeBackground
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.volumeSpike,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          TweenAnimationBuilder<double>(
                                            duration: const Duration(
                                              milliseconds: 1000,
                                            ),
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            builder: (context, value, child) {
                                              return Transform.rotate(
                                                angle: value * 0.5,
                                                child: const Icon(
                                                  Icons.trending_up,
                                                  color: AppColors.volumeSpike,
                                                  size: 20,
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Volume spike: +${(widget.volumeAlert!.spikePercentage * 100).toStringAsFixed(1)}%',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        AppColors.warningDark,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                          AnimatedScale(
                                            scale: _alertOpacityAnimation.value,
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            child: IconButton(
                                              onPressed: () {
                                                context
                                                    .read<CryptocurrencyBloc>()
                                                    .add(
                                                      DismissVolumeAlert(
                                                        widget
                                                            .cryptocurrency
                                                            .symbol,
                                                      ),
                                                    );
                                              },
                                              icon: const Icon(
                                                Icons.close,
                                                size: 16,
                                              ),
                                              color: AppColors.warningDark,
                                              constraints:
                                                  const BoxConstraints(),
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Shimmer overlay for significant updates
                if (_hasSignificantUpdate && _shimmerAnimation.value > -0.5)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            stops: [
                              (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
                              _shimmerAnimation.value.clamp(0.0, 1.0),
                              (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
                            ],
                            colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
