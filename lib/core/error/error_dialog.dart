import 'package:flutter/material.dart';
import 'failures.dart';
import 'error_handler.dart';

/// Dialog that displays user-friendly error messages with recovery options
class ErrorDialog extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool showRecoveryActions;

  const ErrorDialog({
    super.key,
    required this.failure,
    this.onRetry,
    this.onDismiss,
    this.showRecoveryActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final severity = ErrorHandler.getSeverity(failure);
    final recoveryActions = showRecoveryActions
        ? ErrorHandler.getRecoveryActions(failure)
        : <RecoveryAction>[];

    return AlertDialog(
      icon: _buildIcon(severity, theme),
      title: Text(_getTitle(severity)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ErrorHandler.getUserFriendlyMessageWithRecovery(failure),
            style: theme.textTheme.bodyMedium,
          ),
          if (failure.details != null) ...[
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Technical Details'),
              tilePadding: EdgeInsets.zero,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    failure.details!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: _buildActions(context, recoveryActions),
    );
  }

  Widget _buildIcon(ErrorSeverity severity, ThemeData theme) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icon(
          Icons.info_outline,
          color: theme.colorScheme.primary,
          size: 32,
        );
      case ErrorSeverity.warning:
        return Icon(
          Icons.warning_amber_outlined,
          color: theme.colorScheme.tertiary,
          size: 32,
        );
      case ErrorSeverity.error:
        return Icon(
          Icons.error_outline,
          color: theme.colorScheme.error,
          size: 32,
        );
      case ErrorSeverity.critical:
        return Icon(
          Icons.dangerous_outlined,
          color: theme.colorScheme.error,
          size: 32,
        );
    }
  }

  String _getTitle(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return 'Information';
      case ErrorSeverity.warning:
        return 'Connection Issue';
      case ErrorSeverity.error:
        return 'Error Occurred';
      case ErrorSeverity.critical:
        return 'Critical Error';
    }
  }

  List<Widget> _buildActions(
    BuildContext context,
    List<RecoveryAction> actions,
  ) {
    final widgets = <Widget>[];

    // Add recovery action buttons
    for (final action in actions) {
      if (action.type == RecoveryActionType.retry && onRetry != null) {
        widgets.add(
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            icon: const Icon(Icons.refresh),
            label: Text(action.label),
          ),
        );
      } else if (action.type == RecoveryActionType.checkConnection) {
        widgets.add(
          TextButton.icon(
            onPressed: () => _handleRecoveryAction(context, action),
            icon: const Icon(Icons.wifi_find),
            label: Text(action.label),
          ),
        );
      } else if (action.type == RecoveryActionType.refreshData) {
        widgets.add(
          TextButton.icon(
            onPressed: () => _handleRecoveryAction(context, action),
            icon: const Icon(Icons.refresh),
            label: Text(action.label),
          ),
        );
      }
    }

    // Add dismiss button
    widgets.add(
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          onDismiss?.call();
        },
        child: const Text('Dismiss'),
      ),
    );

    return widgets;
  }

  void _handleRecoveryAction(BuildContext context, RecoveryAction action) {
    Navigator.of(context).pop();

    switch (action.type) {
      case RecoveryActionType.checkConnection:
        _showConnectionHelp(context);
        break;
      case RecoveryActionType.refreshData:
        onRetry?.call();
        break;
      case RecoveryActionType.reportIssue:
        _showReportDialog(context);
        break;
      default:
        // Handle other actions as needed
        break;
    }
  }

  void _showConnectionHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Help'),
        content: const Text(
          'To fix connection issues:\n\n'
          '• Check if you have internet access\n'
          '• Try switching between WiFi and mobile data\n'
          '• Restart your router if using WiFi\n'
          '• Check if other apps can connect to the internet\n'
          '• Contact your internet service provider if issues persist',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help us improve by reporting this issue:'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ErrorHandler.getDetailedMessage(failure),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error report sent. Thank you!')),
              );
            },
            child: const Text('Send Report'),
          ),
        ],
      ),
    );
  }

  /// Shows an error dialog
  static Future<void> show(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    bool showRecoveryActions = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        failure: failure,
        onRetry: onRetry,
        onDismiss: onDismiss,
        showRecoveryActions: showRecoveryActions,
      ),
    );
  }
}

/// Snackbar for showing quick error messages
class ErrorSnackBar {
  static void show(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final severity = ErrorHandler.getSeverity(failure);

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getSnackBarIcon(severity),
              color: theme.colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ErrorHandler.getUserFriendlyMessage(failure),
                style: TextStyle(color: theme.colorScheme.onError),
              ),
            ),
          ],
        ),
        backgroundColor: _getSnackBarColor(severity, theme),
        duration: duration,
        action: onRetry != null && ErrorHandler.isRecoverable(failure)
            ? SnackBarAction(
                label: 'Retry',
                textColor: theme.colorScheme.onError,
                onPressed: onRetry,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static IconData _getSnackBarIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber_outlined;
      case ErrorSeverity.error:
      case ErrorSeverity.critical:
        return Icons.error_outline;
    }
  }

  static Color _getSnackBarColor(ErrorSeverity severity, ThemeData theme) {
    switch (severity) {
      case ErrorSeverity.info:
        return theme.colorScheme.primary;
      case ErrorSeverity.warning:
        return theme.colorScheme.tertiary;
      case ErrorSeverity.error:
      case ErrorSeverity.critical:
        return theme.colorScheme.error;
    }
  }
}
