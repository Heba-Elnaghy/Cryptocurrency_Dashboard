import '../entities/entities.dart';

abstract class CryptocurrencyRepository {
  /// Fetches the initial list of 10 specific cryptocurrencies
  /// Returns: List of Cryptocurrency entities
  /// Throws: Exception if the API call fails
  Future<List<Cryptocurrency>> getInitialCryptocurrencies();

  /// Provides a stream of real-time price update events
  /// Returns: Stream of PriceUpdateEvent objects
  Stream<PriceUpdateEvent> getPriceUpdates();

  /// Provides a stream of volume alert notifications
  /// Returns: Stream of VolumeAlert objects when volume spikes occur
  Stream<VolumeAlert> getVolumeAlerts();

  /// Provides a stream of connection status updates
  /// Returns: Stream of ConnectionStatus objects indicating connection state
  Stream<ConnectionStatus> getConnectionStatus();

  /// Starts the real-time update mechanism
  /// This will begin periodic polling for price and volume data
  Future<void> startRealTimeUpdates();

  /// Stops the real-time update mechanism
  /// This will cancel all periodic polling and clean up resources
  Future<void> stopRealTimeUpdates();

  /// Checks if real-time updates are currently active
  /// Returns: true if updates are running, false otherwise
  bool get isUpdating;
}
