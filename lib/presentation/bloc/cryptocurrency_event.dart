import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';

abstract class CryptocurrencyEvent extends Equatable {
  const CryptocurrencyEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial cryptocurrency data
class LoadInitialData extends CryptocurrencyEvent {
  const LoadInitialData();
}

/// Event to start real-time updates
class StartRealTimeUpdates extends CryptocurrencyEvent {
  const StartRealTimeUpdates();
}

/// Event to stop real-time updates
class StopRealTimeUpdates extends CryptocurrencyEvent {
  const StopRealTimeUpdates();
}

/// Event to refresh data manually (pull-to-refresh)
class RefreshData extends CryptocurrencyEvent {
  const RefreshData();
}

/// Event when a price update is received
class PriceUpdated extends CryptocurrencyEvent {
  final PriceUpdateEvent update;

  const PriceUpdated(this.update);

  @override
  List<Object?> get props => [update];
}

/// Event when a volume alert is received
class VolumeAlertReceived extends CryptocurrencyEvent {
  final VolumeAlert alert;

  const VolumeAlertReceived(this.alert);

  @override
  List<Object?> get props => [alert];
}

/// Event when connection status changes
class ConnectionStatusChanged extends CryptocurrencyEvent {
  final ConnectionStatus status;

  const ConnectionStatusChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// Event to dismiss a volume alert
class DismissVolumeAlert extends CryptocurrencyEvent {
  final String symbol;

  const DismissVolumeAlert(this.symbol);

  @override
  List<Object?> get props => [symbol];
}

/// Event when app lifecycle changes (for connection management)
class AppLifecycleChanged extends CryptocurrencyEvent {
  final bool isInForeground;

  const AppLifecycleChanged(this.isInForeground);

  @override
  List<Object?> get props => [isInForeground];
}
