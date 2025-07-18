import 'dart:async';

/// A utility class for debouncing function calls to prevent excessive execution
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  /// Executes the given function after the specified delay
  /// If called again before the delay expires, the previous call is cancelled
  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Cancels any pending debounced call
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Disposes of the debouncer and cancels any pending calls
  void dispose() {
    cancel();
  }
}

/// A specialized debouncer for async operations that returns a Future
class AsyncDebouncer<T> {
  final Duration delay;
  Timer? _timer;
  Completer<T>? _completer;

  AsyncDebouncer({required this.delay});

  /// Executes the given async function after the specified delay
  /// If called again before the delay expires, the previous call is cancelled
  /// Returns a Future that completes when the debounced function executes
  Future<T> call(Future<T> Function() action) {
    // Cancel previous timer and completer
    _timer?.cancel();
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError(Exception('Debounced operation was cancelled'));
    }

    // Create new completer
    _completer = Completer<T>();

    // Set up new timer
    _timer = Timer(delay, () async {
      try {
        final result = await action();
        if (!_completer!.isCompleted) {
          _completer!.complete(result);
        }
      } catch (error) {
        if (!_completer!.isCompleted) {
          _completer!.completeError(error);
        }
      }
    });

    return _completer!.future;
  }

  /// Cancels any pending debounced call
  void cancel() {
    _timer?.cancel();
    _timer = null;
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError(Exception('Debounced operation was cancelled'));
    }
    _completer = null;
  }

  /// Disposes of the debouncer and cancels any pending calls
  void dispose() {
    cancel();
  }
}

/// A utility class for throttling function calls
/// Ensures a function is called at most once per specified duration
class Throttler {
  final Duration duration;
  DateTime? _lastCallTime;

  Throttler({required this.duration});

  /// Executes the given function if enough time has passed since the last call
  /// Returns true if the function was executed, false if throttled
  bool call(void Function() action) {
    final now = DateTime.now();

    if (_lastCallTime == null || now.difference(_lastCallTime!) >= duration) {
      _lastCallTime = now;
      action();
      return true;
    }

    return false;
  }

  /// Resets the throttler, allowing the next call to execute immediately
  void reset() {
    _lastCallTime = null;
  }
}

/// A utility class for batching multiple operations together
/// Useful for batching state updates or API calls
class Batcher<T> {
  final Duration delay;
  final void Function(List<T>) onBatch;
  final List<T> _items = [];
  Timer? _timer;

  Batcher({required this.delay, required this.onBatch});

  /// Adds an item to the batch
  /// If this is the first item, starts the batch timer
  void add(T item) {
    _items.add(item);

    _timer ??= Timer(delay, _processBatch);
  }

  /// Forces immediate processing of the current batch
  void flush() {
    _timer?.cancel();
    _timer = null;
    _processBatch();
  }

  void _processBatch() {
    if (_items.isNotEmpty) {
      final batch = List<T>.from(_items);
      _items.clear();
      onBatch(batch);
    }
    _timer = null;
  }

  /// Disposes the batcher and processes any remaining items
  void dispose() {
    flush();
  }
}

/// A rate limiter that ensures a minimum interval between function executions
class IntervalRateLimiter {
  final Duration minInterval;
  DateTime? _lastExecution;
  Timer? _pendingTimer;

  IntervalRateLimiter({required this.minInterval});

  /// Executes the given function, ensuring minimum interval between calls
  /// If called too frequently, the execution is delayed
  Future<void> execute(Future<void> Function() action) async {
    final now = DateTime.now();

    if (_lastExecution == null) {
      // First execution
      _lastExecution = now;
      await action();
      return;
    }

    final timeSinceLastExecution = now.difference(_lastExecution!);

    if (timeSinceLastExecution >= minInterval) {
      // Enough time has passed, execute immediately
      _lastExecution = now;
      await action();
    } else {
      // Need to wait, schedule for later
      final waitTime = minInterval - timeSinceLastExecution;

      // Cancel any existing pending timer
      _pendingTimer?.cancel();

      final completer = Completer<void>();
      _pendingTimer = Timer(waitTime, () async {
        _lastExecution = DateTime.now();
        try {
          await action();
          completer.complete();
        } catch (error) {
          completer.completeError(error);
        }
      });

      return completer.future;
    }
  }

  /// Cancels any pending execution
  void cancel() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
  }

  /// Disposes of the rate limiter
  void dispose() {
    cancel();
  }
}

/// A utility class for rate limiting function calls
/// Ensures a function is not called more than a specified number of times per duration
class RateLimiter {
  final int maxCalls;
  final Duration duration;
  final List<DateTime> _callTimes = [];

  RateLimiter({required this.maxCalls, required this.duration});

  /// Attempts to execute the given function
  /// Returns true if executed, false if rate limited
  bool call(void Function() action) {
    final now = DateTime.now();

    // Remove old call times outside the duration window
    _callTimes.removeWhere((time) => now.difference(time) > duration);

    // Check if we can make another call
    if (_callTimes.length < maxCalls) {
      _callTimes.add(now);
      action();
      return true;
    }

    return false;
  }

  /// Gets the time until the next call can be made
  Duration? getTimeUntilNextCall() {
    if (_callTimes.length < maxCalls) {
      return Duration.zero;
    }

    final oldestCall = _callTimes.first;
    final timeUntilExpiry = duration - DateTime.now().difference(oldestCall);

    return timeUntilExpiry.isNegative ? Duration.zero : timeUntilExpiry;
  }

  /// Resets the rate limiter
  void reset() {
    _callTimes.clear();
  }
}
