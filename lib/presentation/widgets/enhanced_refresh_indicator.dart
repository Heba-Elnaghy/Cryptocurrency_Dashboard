import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import 'dart:math' as math;

class EnhancedRefreshIndicator extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? color;
  final Color? backgroundColor;
  final double strokeWidth;
  final double displacement;

  const EnhancedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 2.0,
    this.displacement = 40.0,
  });

  @override
  State<EnhancedRefreshIndicator> createState() =>
      _EnhancedRefreshIndicatorState();
}

class _EnhancedRefreshIndicatorState extends State<EnhancedRefreshIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pullController;
  late AnimationController _refreshController;
  late AnimationController _successController;

  late Animation<double> _refreshRotationAnimation;
  late Animation<double> _refreshScaleAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<Color?> _successColorAnimation;
  late Animation<double> _pullProgressAnimation;

  bool _isRefreshing = false;
  bool _showSuccess = false;
  double _pullDistance = 0.0;
  bool _canRefresh = false;
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_animationsInitialized) {
      _initializeAnimations();
      _animationsInitialized = true;
    }
  }

  void _initializeControllers() {
    // Pull animation controller
    _pullController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // Refresh animation controller
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Success animation controller
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  void _initializeAnimations() {
    // Refresh rotation animation
    _refreshRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _refreshController, curve: Curves.linear),
    );

    // Refresh scale animation with bounce
    _refreshScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.8, end: 1.2),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.2, end: 1.0),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(parent: _refreshController, curve: Curves.elasticOut),
        );

    // Success scale animation
    _successScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    // Success color animation - now safe to access Theme.of(context)
    _successColorAnimation =
        ColorTween(
          begin: widget.color ?? Theme.of(context).colorScheme.primary,
          end: AppColors.success,
        ).animate(
          CurvedAnimation(parent: _successController, curve: Curves.easeInOut),
        );

    // Pull progress animation for visual feedback during pull
    _pullProgressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pullController, curve: Curves.easeOut));
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _showSuccess = false;
    });

    // Start refresh animations
    _refreshController.repeat();

    try {
      await widget.onRefresh();

      // Show success animation
      setState(() {
        _showSuccess = true;
      });

      _refreshController.stop();
      _successController.forward();

      // Wait for success animation to complete
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (error) {
      // Handle error - could add error animation here
      _refreshController.stop();
    } finally {
      setState(() {
        _isRefreshing = false;
        _showSuccess = false;
      });

      _successController.reset();
    }
  }

  @override
  void dispose() {
    _pullController.dispose();
    _refreshController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: widget.color ?? theme.colorScheme.primary,
      backgroundColor: widget.backgroundColor ?? theme.colorScheme.surface,
      strokeWidth: widget.strokeWidth,
      displacement: widget.displacement,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification && !_isRefreshing) {
            final pixels = notification.metrics.pixels;

            // Enhanced pull feedback with progressive animation
            if (pixels < 0) {
              final pullDistance = (-pixels).clamp(0.0, 100.0);
              final pullProgress = (pullDistance / 100.0).clamp(0.0, 1.0);

              setState(() {
                _pullDistance = pullDistance;
                _canRefresh = pullDistance > 60.0;
              });

              // Animate pull controller based on pull distance
              _pullController.value = pullProgress;
            } else {
              // Reset when not pulling
              if (_pullDistance > 0) {
                setState(() {
                  _pullDistance = 0.0;
                  _canRefresh = false;
                });
                _pullController.reverse();
              }
            }
          }
          return false;
        },
        child: Stack(
          children: [
            widget.child,

            // Pull feedback indicator
            if (_pullDistance > 0 && !_isRefreshing)
              Positioned(
                top: widget.displacement - 20,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pullProgressAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pullProgressAnimation.value,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color:
                                (_canRefresh
                                        ? AppColors.success
                                        : theme.colorScheme.primary)
                                    .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _canRefresh
                                  ? AppColors.success
                                  : theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Progress ring
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  value: _pullDistance / 100.0,
                                  strokeWidth: 3,
                                  color: _canRefresh
                                      ? AppColors.success
                                      : theme.colorScheme.primary,
                                  backgroundColor: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                              // Icon
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  _canRefresh
                                      ? Icons.refresh
                                      : Icons.arrow_downward,
                                  key: ValueKey(_canRefresh),
                                  color: _canRefresh
                                      ? AppColors.success
                                      : theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Enhanced refresh indicator overlay
            if (_isRefreshing || _showSuccess)
              Positioned(
                top: widget.displacement,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _refreshRotationAnimation,
                      _refreshScaleAnimation,
                      _successScaleAnimation,
                      _successColorAnimation,
                    ]),
                    builder: (context, child) {
                      if (_showSuccess) {
                        return Transform.scale(
                          scale: _successScaleAnimation.value,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _successColorAnimation.value?.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    _successColorAnimation.value ??
                                    AppColors.success,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.check,
                              color: _successColorAnimation.value,
                              size: 24,
                            ),
                          ),
                        );
                      }

                      return Transform.scale(
                        scale: _refreshScaleAnimation.value,
                        child: Transform.rotate(
                          angle: _refreshRotationAnimation.value * 2 * 3.14159,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color:
                                  (widget.backgroundColor ??
                                          theme.colorScheme.surface)
                                      .withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: _EnhancedRefreshPainter(
                                color:
                                    widget.color ?? theme.colorScheme.primary,
                                strokeWidth: widget.strokeWidth,
                                progress: _refreshRotationAnimation.value,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EnhancedRefreshPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double progress;

  _EnhancedRefreshPainter({
    required this.color,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw animated arc
    final startAngle = -3.14159 / 2; // Start from top
    final sweepAngle = 2 * 3.14159 * 0.75; // 3/4 circle

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle + (progress * 2 * 3.14159),
      sweepAngle,
      false,
      paint,
    );

    // Draw dots for enhanced visual feedback
    for (int i = 0; i < 3; i++) {
      final angle = (progress * 2 * 3.14159) + (i * 0.5);
      final dotX = center.dx + (radius * 0.7) * math.cos(angle);
      final dotY = center.dy + (radius * 0.7) * math.sin(angle);

      final dotPaint = Paint()
        ..color = color.withValues(alpha: 0.6 - (i * 0.2))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dotX, dotY), 2 - (i * 0.5), dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
