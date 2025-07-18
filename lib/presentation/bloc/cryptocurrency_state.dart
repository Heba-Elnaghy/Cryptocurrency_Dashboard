import '../../domain/entities/entities.dart';
import '../../core/utils/immutable_state.dart';

abstract class CryptocurrencyState extends ImmutableState {
  const CryptocurrencyState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the BLoC is first created
class CryptocurrencyInitial extends CryptocurrencyState {
  const CryptocurrencyInitial();
}

/// State when loading initial data
class CryptocurrencyLoading extends CryptocurrencyState {
  final String? message;

  const CryptocurrencyLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State when data is successfully loaded and being displayed
class CryptocurrencyLoaded extends CryptocurrencyState
    with
        CopyableMixin<CryptocurrencyLoaded>,
        ListStateMixin<CryptocurrencyLoaded, Cryptocurrency>,
        MemoizationMixin {
  final List<Cryptocurrency> cryptocurrencies;
  final ConnectionStatus connectionStatus;
  final Map<String, VolumeAlert> activeAlerts;
  final bool isRefreshing;
  final DateTime lastUpdated;

  CryptocurrencyLoaded({
    required this.cryptocurrencies,
    required this.connectionStatus,
    this.activeAlerts = const {},
    this.isRefreshing = false,
    required this.lastUpdated,
  });

  @override
  List<Cryptocurrency> get items => cryptocurrencies;

  /// Creates a copy of this state with updated values
  @override
  CryptocurrencyLoaded copyWith({
    List<Cryptocurrency>? cryptocurrencies,
    ConnectionStatus? connectionStatus,
    Map<String, VolumeAlert>? activeAlerts,
    bool? isRefreshing,
    DateTime? lastUpdated,
  }) {
    return CryptocurrencyLoaded(
      cryptocurrencies: cryptocurrencies ?? this.cryptocurrencies,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      activeAlerts: activeAlerts ?? this.activeAlerts,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Creates a copy only if any of the provided values are different
  @override
  CryptocurrencyLoaded copyWithIfChanged(Map<String, dynamic> changes) {
    final updater = StateUpdater(this);

    if (changes.containsKey('cryptocurrencies')) {
      updater.update(
        'cryptocurrencies',
        changes['cryptocurrencies'],
        (state) => state.cryptocurrencies,
      );
    }
    if (changes.containsKey('connectionStatus')) {
      updater.update(
        'connectionStatus',
        changes['connectionStatus'],
        (state) => state.connectionStatus,
      );
    }
    if (changes.containsKey('activeAlerts')) {
      updater.update(
        'activeAlerts',
        changes['activeAlerts'],
        (state) => state.activeAlerts,
      );
    }
    if (changes.containsKey('isRefreshing')) {
      updater.update(
        'isRefreshing',
        changes['isRefreshing'],
        (state) => state.isRefreshing,
      );
    }
    if (changes.containsKey('lastUpdated')) {
      updater.update(
        'lastUpdated',
        changes['lastUpdated'],
        (state) => state.lastUpdated,
      );
    }

    return updater.build(
      (changes) => copyWith(
        cryptocurrencies: changes['cryptocurrencies'],
        connectionStatus: changes['connectionStatus'],
        activeAlerts: changes['activeAlerts'],
        isRefreshing: changes['isRefreshing'],
        lastUpdated: changes['lastUpdated'],
      ),
    );
  }

  /// Updates a specific cryptocurrency in the list using optimized list operations
  CryptocurrencyLoaded updateCryptocurrency(Cryptocurrency updatedCrypto) {
    return updateItem(
      updatedCrypto.symbol,
      (_) => updatedCrypto,
      (crypto) => crypto.symbol,
      (updatedList) =>
          copyWith(cryptocurrencies: updatedList, lastUpdated: DateTime.now()),
    );
  }

  /// Updates multiple cryptocurrencies efficiently
  CryptocurrencyLoaded updateCryptocurrencies(
    Map<String, Cryptocurrency> updates,
  ) {
    final updateMap = updates.map(
      (symbol, crypto) => MapEntry(symbol, (_) => crypto),
    );

    return updateItems(
      updateMap,
      (crypto) => crypto.symbol,
      (updatedList) =>
          copyWith(cryptocurrencies: updatedList, lastUpdated: DateTime.now()),
    );
  }

  /// Adds or updates a volume alert with optimized state update
  CryptocurrencyLoaded addVolumeAlert(VolumeAlert alert) {
    // Only create new map if the alert is different
    if (activeAlerts[alert.symbol] == alert) {
      return this;
    }

    final updatedAlerts = Map<String, VolumeAlert>.from(activeAlerts);
    updatedAlerts[alert.symbol] = alert;

    return copyWith(activeAlerts: updatedAlerts, lastUpdated: DateTime.now());
  }

  /// Removes a volume alert with optimized state update
  CryptocurrencyLoaded removeVolumeAlert(String symbol) {
    // Only update if the alert exists
    if (!activeAlerts.containsKey(symbol)) {
      return this;
    }

    final updatedAlerts = Map<String, VolumeAlert>.from(activeAlerts);
    updatedAlerts.remove(symbol);

    // Also update the cryptocurrency to remove volume spike flag
    return updateItem(
      symbol,
      (crypto) => crypto.copyWith(hasVolumeSpike: false),
      (crypto) => crypto.symbol,
      (updatedCryptos) => CryptocurrencyLoaded(
        cryptocurrencies: updatedCryptos,
        connectionStatus: connectionStatus,
        activeAlerts: updatedAlerts,
        isRefreshing: isRefreshing,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// Gets cryptocurrencies with volume spikes (memoized for performance)
  List<Cryptocurrency> get cryptocurrenciesWithVolumeSpikes {
    return memoize('volumeSpikes', () {
      return cryptocurrencies.where((crypto) => crypto.hasVolumeSpike).toList();
    });
  }

  /// Gets connected status (memoized for performance)
  bool get isConnected {
    return memoize('isConnected', () => connectionStatus.isConnected);
  }

  /// Gets the number of active alerts (memoized for performance)
  int get activeAlertCount {
    return memoize('alertCount', () => activeAlerts.length);
  }

  /// Optimized equality comparison that checks specific fields
  @override
  bool isEqualTo(covariant CryptocurrencyLoaded other) {
    // Quick reference equality check
    if (identical(this, other)) return true;

    // Check if lists are the same reference (common case for immutable updates)
    if (identical(cryptocurrencies, other.cryptocurrencies) &&
        identical(activeAlerts, other.activeAlerts) &&
        connectionStatus == other.connectionStatus &&
        isRefreshing == other.isRefreshing &&
        lastUpdated == other.lastUpdated) {
      return true;
    }

    // Fall back to deep comparison
    return DeepEquality.equals(cryptocurrencies, other.cryptocurrencies) &&
        connectionStatus == other.connectionStatus &&
        DeepEquality.equals(activeAlerts, other.activeAlerts) &&
        isRefreshing == other.isRefreshing &&
        lastUpdated == other.lastUpdated;
  }

  @override
  List<Object?> get props => [
    cryptocurrencies,
    connectionStatus,
    activeAlerts,
    isRefreshing,
    lastUpdated,
  ];
}

/// State when an error occurs
class CryptocurrencyError extends CryptocurrencyState {
  final String message;
  final String? details;
  final bool canRetry;
  final List<Cryptocurrency>? previousData;

  const CryptocurrencyError({
    required this.message,
    this.details,
    this.canRetry = true,
    this.previousData,
  });

  @override
  List<Object?> get props => [message, details, canRetry, previousData];
}

/// State when refreshing data (pull-to-refresh)
class CryptocurrencyRefreshing extends CryptocurrencyLoaded {
  CryptocurrencyRefreshing({
    required super.cryptocurrencies,
    required super.connectionStatus,
    super.activeAlerts,
    required super.lastUpdated,
  }) : super(isRefreshing: true);
}
