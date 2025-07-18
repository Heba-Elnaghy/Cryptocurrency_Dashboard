import 'package:equatable/equatable.dart';

/// A base class for creating immutable state objects with optimized equality checks
abstract class ImmutableState extends Equatable {
  const ImmutableState();

  /// Override this to provide custom equality comparison
  /// This can be more efficient than comparing all props for large objects
  bool isEqualTo(covariant ImmutableState other) {
    return props == other.props;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ImmutableState) return false;
    if (runtimeType != other.runtimeType) return false;

    return isEqualTo(other);
  }

  @override
  int get hashCode => props.hashCode;
}

/// A mixin that provides efficient state copying capabilities
mixin CopyableMixin<T> {
  /// Creates a copy of this object with the specified changes
  T copyWith();

  /// Creates a copy only if any of the provided values are different
  T copyWithIfChanged(Map<String, dynamic> changes) {
    // This should be implemented by subclasses to check if changes are needed
    return copyWith();
  }
}

/// A utility class for creating efficient state updates
class StateUpdater<T extends ImmutableState> {
  final T _currentState;
  final Map<String, dynamic> _changes = {};
  bool _hasChanges = false;

  StateUpdater(this._currentState);

  /// Adds a field change if the new value is different from the current value
  StateUpdater<T> update<V>(
    String fieldName,
    V newValue,
    V Function(T) currentValueGetter,
  ) {
    final currentValue = currentValueGetter(_currentState);
    if (currentValue != newValue) {
      _changes[fieldName] = newValue;
      _hasChanges = true;
    }
    return this;
  }

  /// Builds the new state if there are changes, otherwise returns the current state
  T build(T Function(Map<String, dynamic> changes) builder) {
    if (!_hasChanges) {
      return _currentState;
    }
    return builder(_changes);
  }

  /// Returns true if any changes were made
  bool get hasChanges => _hasChanges;

  /// Gets the map of changes
  Map<String, dynamic> get changes => Map.unmodifiable(_changes);
}

/// A utility for batching multiple state updates
class StateBatcher<T extends ImmutableState> {
  final List<T Function(T)> _updates = [];

  /// Adds an update function to the batch
  StateBatcher<T> add(T Function(T) update) {
    _updates.add(update);
    return this;
  }

  /// Applies all updates to the state in sequence
  T apply(T initialState) {
    return _updates.fold(initialState, (state, update) => update(state));
  }

  /// Clears all pending updates
  void clear() {
    _updates.clear();
  }

  /// Returns the number of pending updates
  int get length => _updates.length;

  /// Returns true if there are no pending updates
  bool get isEmpty => _updates.isEmpty;
}

/// A mixin that provides optimized list operations for state objects
mixin ListStateMixin<T, I> on ImmutableState {
  List<I> get items;

  /// Updates a single item in the list by ID
  T updateItem(
    dynamic id,
    I Function(I) updater,
    dynamic Function(I) idGetter,
    T Function(List<I>) stateBuilder,
  ) {
    final updatedItems = items.map((item) {
      return idGetter(item) == id ? updater(item) : item;
    }).toList();

    return stateBuilder(updatedItems);
  }

  /// Updates multiple items in the list
  T updateItems(
    Map<dynamic, I Function(I)> updates,
    dynamic Function(I) idGetter,
    T Function(List<I>) stateBuilder,
  ) {
    final updatedItems = items.map((item) {
      final id = idGetter(item);
      final updater = updates[id];
      return updater != null ? updater(item) : item;
    }).toList();

    return stateBuilder(updatedItems);
  }

  /// Adds an item to the list
  T addItem(I item, T Function(List<I>) stateBuilder) {
    final updatedItems = [...items, item];
    return stateBuilder(updatedItems);
  }

  /// Removes an item from the list by ID
  T removeItem(
    dynamic id,
    dynamic Function(I) idGetter,
    T Function(List<I>) stateBuilder,
  ) {
    final updatedItems = items.where((item) => idGetter(item) != id).toList();
    return stateBuilder(updatedItems);
  }

  /// Replaces the entire list
  T replaceItems(List<I> newItems, T Function(List<I>) stateBuilder) {
    return stateBuilder(newItems);
  }
}

/// A utility for creating efficient deep equality comparisons
class DeepEquality {
  /// Compares two objects for deep equality
  static bool equals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.runtimeType != b.runtimeType) return false;

    if (a is List && b is List) {
      return _listEquals(a, b);
    }

    if (a is Map && b is Map) {
      return _mapEquals(a, b);
    }

    if (a is Set && b is Set) {
      return _setEquals(a, b);
    }

    return a == b;
  }

  static bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!equals(a[i], b[i])) return false;
    }
    return true;
  }

  static bool _mapEquals(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !equals(a[key], b[key])) return false;
    }
    return true;
  }

  static bool _setEquals(Set a, Set b) {
    if (a.length != b.length) return false;
    return a.every((element) => b.contains(element));
  }
}

/// A mixin that provides memoization capabilities for expensive computations
mixin MemoizationMixin {
  final Map<String, dynamic> _memoCache = {};

  /// Memoizes the result of an expensive computation
  T memoize<T>(String key, T Function() computation) {
    if (_memoCache.containsKey(key)) {
      return _memoCache[key] as T;
    }

    final result = computation();
    _memoCache[key] = result;
    return result;
  }

  /// Clears the memoization cache
  void clearMemoCache() {
    _memoCache.clear();
  }

  /// Removes a specific key from the memoization cache
  void removeMemoKey(String key) {
    _memoCache.remove(key);
  }
}
