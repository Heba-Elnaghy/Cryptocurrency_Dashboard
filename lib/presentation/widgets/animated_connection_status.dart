import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';
import '../../core/constants/constants.dart';

class AnimatedConnectionStatus extends StatefulWidget {
  final ConnectionStatus connectionStatus;
  final TextStyle? textStyle;

  const AnimatedConnectionStatus({
    super.key,
    required this.connectionStatus,
    this.textStyle,
  });

  @override
  State<AnimatedConnectionStatus> createState() =>
      _AnimatedConnectionStatusState();
}

class _AnimatedConnectionStatusState extends State<AnimatedConnectionStatus>
    with TickerProviderStateMixin {
  late AnimationController _statusTransitionController;
  late AnimationController _spinnerController;
  late AnimationController _slideController;
  late AnimationController _pulseController;

  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  ConnectionStatus? _previousStatus;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _statusTransitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _spinnerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Initialize animations
    _initializeAnimations();

    // Start initial animation
    _statusTransitionController.forward();
    _slideController.forward();

    // Start appropriate animations based on status
    _startStatusAnimations(widget.connectionStatus);
  }

  void _initializeAnimations() {
    final currentStatus = widget.connectionStatus;

    // Color animation for status indicator with smoother transitions
    _colorAnimation =
        ColorTween(
          begin: _getStatusColor(_previousStatus),
          end: _getStatusColor(currentStatus),
        ).animate(
          CurvedAnimation(
            parent: _statusTransitionController,
            curve: Curves.easeInOutCubic,
          ),
        );

    // Scale animation for status indicator with more elastic feel
    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _statusTransitionController,
        curve: Curves.elasticOut,
      ),
    );

    // Slide animation for status message with smoother curve
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Pulse animation for connecting state with more subtle effect
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Fade animation for smooth text transitions
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
  }

  void _startStatusAnimations(ConnectionStatus status) {
    // Start spinner animation for connecting states
    if (_isConnecting(status)) {
      _spinnerController.repeat();
      _pulseController.repeat(reverse: true);
    } else {
      _spinnerController.stop();
      _pulseController.stop();
    }
  }

  @override
  void didUpdateWidget(AnimatedConnectionStatus oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.connectionStatus != widget.connectionStatus) {
      _previousStatus = oldWidget.connectionStatus;
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    // Reset and restart transition animation
    _statusTransitionController.reset();
    _slideController.reset();

    _initializeAnimations();

    _statusTransitionController.forward();
    _slideController.forward();

    // Start appropriate animations based on new status
    _startStatusAnimations(widget.connectionStatus);
  }

  bool _isConnecting(ConnectionStatus status) {
    final message = status.statusMessage.toLowerCase();
    return message.contains('connecting') ||
        message.contains('reconnecting') ||
        message.contains('starting') ||
        message.contains('retrying');
  }

  bool _isLive(ConnectionStatus status) {
    return status.isConnected && status.statusMessage.toLowerCase() == 'live';
  }

  Color _getStatusColor(ConnectionStatus? status) {
    if (status == null) return AppColors.priceNeutral;

    if (_isConnecting(status)) {
      return AppColors.connecting;
    } else if (_isLive(status)) {
      return AppColors.liveData;
    } else if (status.isConnected) {
      return AppColors.connected;
    } else {
      return AppColors.disconnected;
    }
  }

  Widget _buildStatusIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _statusTransitionController,
        _spinnerController,
        _pulseController,
      ]),
      builder: (context, child) {
        final baseScale = _scaleAnimation.value;
        final pulseScale = _isConnecting(widget.connectionStatus)
            ? _pulseAnimation.value
            : 1.0;
        final statusColor =
            _colorAnimation.value ?? _getStatusColor(widget.connectionStatus);

        return Transform.scale(
          scale: baseScale * pulseScale,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: _isConnecting(widget.connectionStatus)
                  ? [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 6 * _pulseAnimation.value,
                        spreadRadius: 2 * _pulseAnimation.value,
                      ),
                    ]
                  : _isLive(widget.connectionStatus)
                  ? [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 3,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: _isConnecting(widget.connectionStatus)
                ? ClipOval(
                    child: Transform.rotate(
                      angle: _spinnerController.value * 2 * 3.14159,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.withOpacity(statusColor, 0.3),
                              statusColor,
                              AppColors.withOpacity(statusColor, 0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildStatusMessage() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _statusTransitionController,
          builder: (context, child) {
            return Text(
              widget.connectionStatus.statusMessage,
              style: (widget.textStyle ?? Theme.of(context).textTheme.bodySmall)
                  ?.copyWith(
                    color:
                        _colorAnimation.value ??
                        _getStatusColor(widget.connectionStatus),
                    fontWeight: FontWeight.w500,
                  ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusIndicator(),
        const SizedBox(width: 8),
        _buildStatusMessage(),
      ],
    );
  }

  @override
  void dispose() {
    _statusTransitionController.dispose();
    _spinnerController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
