import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';

class AnimatedPriceDisplay extends StatefulWidget {
  final double price;
  final double priceChange;
  final TextStyle? priceStyle;
  final TextStyle? changeStyle;
  final Duration animationDuration;

  const AnimatedPriceDisplay({
    super.key,
    required this.price,
    required this.priceChange,
    this.priceStyle,
    this.changeStyle,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedPriceDisplay> createState() => _AnimatedPriceDisplayState();
}

class _AnimatedPriceDisplayState extends State<AnimatedPriceDisplay>
    with TickerProviderStateMixin {
  late AnimationController _flashController;
  late AnimationController _scaleController;
  late AnimationController _colorController;
  late AnimationController _pulseController;

  late Animation<double> _flashAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _pulseAnimation;

  double? _previousPrice;
  bool _isPositiveChange = false;
  double _priceDifferencePercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _previousPrice = widget.price;
  }

  void _initializeAnimations() {
    // Flash animation controller
    _flashController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    // Scale animation controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Color animation controller
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Pulse animation controller for continuous subtle animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Flash animation (opacity)
    _flashAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeInOut),
    );

    // Scale animation with more dynamic curve - will be updated based on price change
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Pulse animation for subtle continuous effect
    _pulseAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.02),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.02, end: 1.0),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        );

    // Start continuous pulse animation
    _pulseController.repeat();

    // Color animation will be initialized in didUpdateWidget
    _updateColorAnimation();
  }

  void _updateColorAnimation() {
    // Base colors with more vibrant shades for larger price changes
    final baseColor = _isPositiveChange
        ? AppColors.priceUp
        : AppColors.priceDown;

    // Make highlight color more intense for larger price changes
    final highlightIntensity = _priceDifferencePercentage.clamp(0.0, 0.1) * 10;
    final highlightColor = _isPositiveChange
        ? Color.lerp(
            AppColors.priceUpLight,
            AppColors.flashPositive,
            highlightIntensity,
          )!
        : Color.lerp(
            AppColors.priceDownLight,
            AppColors.flashNegative,
            highlightIntensity,
          )!;

    _colorAnimation = ColorTween(begin: baseColor, end: highlightColor).animate(
      CurvedAnimation(parent: _colorController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedPriceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if price changed
    if (oldWidget.price != widget.price && _previousPrice != null) {
      _isPositiveChange = widget.price > _previousPrice!;

      // Calculate price difference percentage for animation intensity
      if (_previousPrice! > 0) {
        _priceDifferencePercentage =
            (widget.price - _previousPrice!).abs() / _previousPrice!;
      } else {
        _priceDifferencePercentage = 0.0;
      }

      _updateColorAnimation();
      _triggerAnimations();
    }

    _previousPrice = widget.price;
  }

  void _triggerAnimations() {
    // Update scale animation based on price change magnitude
    final scaleIntensity = (_priceDifferencePercentage * 10).clamp(0.05, 0.25);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0 + scaleIntensity)
        .animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
        );

    // Reset all animations
    _flashController.reset();
    _scaleController.reset();
    _colorController.reset();

    // Start animations with proper timing
    _flashController.forward().then((_) {
      _flashController.reverse();
    });

    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });

    _colorController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _colorController.reverse();
      });
    });
  }

  @override
  void dispose() {
    _flashController.dispose();
    _scaleController.dispose();
    _colorController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPositiveChange = widget.priceChange >= 0;
    final changeColor = AppColors.getPriceChangeColor(widget.priceChange);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _flashAnimation,
        _scaleAnimation,
        _colorAnimation,
        _pulseAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Price display with flash effect
              Container(
                decoration: BoxDecoration(
                  color: _colorAnimation.value?.withValues(
                    alpha: _flashAnimation.value * 0.3,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  '\$${widget.price.toStringAsFixed(2)}',
                  style: (widget.priceStyle ?? theme.textTheme.titleLarge)
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color:
                            _colorAnimation.value ??
                            theme.colorScheme.onSurface,
                      ),
                ),
              ),

              // Price change with animated color
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _scaleAnimation.value > 1.05 ? 0.1 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isPositiveChange
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: _colorAnimation.value ?? changeColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${isPositiveChange ? '+' : ''}\$${widget.priceChange.toStringAsFixed(2)}',
                        style:
                            (widget.changeStyle ?? theme.textTheme.bodyMedium)
                                ?.copyWith(
                                  color: _colorAnimation.value ?? changeColor,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'monospace',
                                ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
