import 'package:flutter/material.dart';
import 'offline_manager.dart';
import 'offline_detector.dart';

/// Widget that displays offline status indicator
class OfflineIndicator extends StatefulWidget {
  final Widget child;
  final OfflineManager offlineManager;
  final OfflineDetector? offlineDetector;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration animationDuration;
  final bool showOnlyWhenOffline;
  final String? customMessage;

  const OfflineIndicator({
    super.key,
    required this.child,
    required this.offlineManager,
    this.offlineDetector,
    this.backgroundColor,
    this.textColor,
    this.animationDuration = const Duration(milliseconds: 300),
    this.showOnlyWhenOffline = true,
    this.customMessage,
  });

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isOffline = false;
  String _offlineMessage = '';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupListeners();
    _checkInitialState();
  }

  void _setupAnimations() {
    _slideController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  void _setupListeners() {
    // Listen to offline state changes
    widget.offlineManager.onOfflineStateChanged.listen(_handleOfflineStateChange);

    // Listen to offline detection events if available
    widget.offlineDetector?.events.listen(_handleOfflineDetectionEvent);
  }

  void _checkInitialState() {
    _isOffline = widget.offlineManager.isOffline;
    _offlineMessage = _getOfflineMessage();

    if (_isOffline && widget.showOnlyWhenOffline) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showIndicator();
      });
    }
  }

  void _handleOfflineStateChange(OfflineState state) {
    setState(() {
      _isOffline = state.isOffline;
      _offlineMessage = _getOfflineMessage();
    });

    if (state.wentOffline && widget.showOnlyWhenOffline) {
      _showIndicator();
    } else if (state.wentOnline) {
      _hideIndicator();
    }
  }

  void _handleOfflineDetectionEvent(OfflineDetectionEvent event) {
    if (event is OfflineDetectionWentOffline) {
      setState(() {
        _isOffline = true;
        _offlineMessage = _getOfflineMessage();
      });
      if (widget.showOnlyWhenOffline) {
        _showIndicator();
      }
    } else if (event is OfflineDetectionBackOnline) {
      setState(() {
        _isOffline = false;
        _offlineMessage = _getOfflineMessage();
      });
      _hideIndicator();
    }
  }

  String _getOfflineMessage() {
    if (widget.customMessage != null) {
      return widget.customMessage!;
    }

    if (widget.offlineDetector != null) {
      return widget.offlineDetector!.getOfflineMessage();
    }

    return widget.offlineManager.getOfflineMessage();
  }

  void _showIndicator() {
    _slideController.forward();
    _fadeController.forward();
  }

  void _hideIndicator() {
    _slideController.reverse();
    _fadeController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_shouldShowIndicator())
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildIndicatorBar(context),
              ),
            ),
          ),
      ],
    );
  }

  bool _shouldShowIndicator() {
    if (widget.showOnlyWhenOffline) {
      return _isOffline;
    }
    return true; // Always show if not configured to show only when offline
  }

  Widget _buildIndicatorBar(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? 
        (_isOffline ? Colors.red.shade600 : Colors.green.shade600);
    final textColor = widget.textColor ?? Colors.white;

    return Material(
      color: backgroundColor,
      elevation: 4,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                _isOffline ? Icons.wifi_off : Icons.wifi,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isOffline ? _offlineMessage : 'Back online',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isOffline) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(textColor),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
}

/// Simplified offline indicator that shows a banner
class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final String message;
  final VoidCallback? onRetry;
  final Color? backgroundColor;
  final Color? textColor;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    required this.message,
    this.onRetry,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? Colors.red.shade600;
    final txtColor = textColor ?? Colors.white;

    return Material(
      color: bgColor,
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: txtColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: txtColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: 12),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: txtColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Connection status indicator widget
class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String statusMessage;
  final bool isLoading;
  final VoidCallback? onTap;

  const ConnectionStatusIndicator({
    super.key,
    required this.isConnected,
    required this.statusMessage,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color statusColor;
    IconData statusIcon;
    
    if (isLoading) {
      statusColor = Colors.orange;
      statusIcon = Icons.sync;
    } else if (isConnected) {
      statusColor = Colors.green;
      statusIcon = Icons.wifi;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.wifi_off;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              )
            else
              Icon(statusIcon, color: statusColor, size: 12),
            const SizedBox(width: 4),
            Text(
              statusMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}