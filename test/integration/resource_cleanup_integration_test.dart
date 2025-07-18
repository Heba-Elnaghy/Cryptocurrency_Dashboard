import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_dashboard/core/utils/debouncer.dart';

void main() {
  group('Resource Cleanup Integration Tests', () {
    group('Debouncer Resource Cleanup', () {
      test('should cancel timer when dispose is called', () async {
        // Arrange
        final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
        bool actionExecuted = false;

        // Act
        debouncer.call(() => actionExecuted = true);
        debouncer.dispose(); // Should cancel the pending action

        // Wait longer than the delay to ensure action would have executed
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        expect(actionExecuted, isFalse);
      });

      test('should handle multiple dispose calls gracefully', () {
        // Arrange
        final debouncer = Debouncer(delay: const Duration(milliseconds: 100));

        // Act & Assert - should not throw
        expect(() {
          debouncer.dispose();
          debouncer.dispose(); // Second call should be safe
        }, returnsNormally);
      });
    });

    group('AsyncDebouncer Resource Cleanup', () {
      test('should cancel pending operation when dispose is called', () async {
        // Arrange
        final debouncer = AsyncDebouncer<String>(
          delay: const Duration(milliseconds: 100),
        );
        bool actionExecuted = false;

        // Act
        final future = debouncer.call(() async {
          actionExecuted = true;
          return 'result';
        });
        debouncer.dispose(); // Should cancel the pending action

        // Assert
        await expectLater(future, throwsA(isA<Exception>()));
        expect(actionExecuted, isFalse);
      });
    });

    group('Batcher Resource Cleanup', () {
      test('should process remaining items when dispose is called', () async {
        // Arrange
        final processedItems = <String>[];
        final batcher = Batcher<String>(
          delay: const Duration(milliseconds: 100),
          onBatch: (items) => processedItems.addAll(items),
        );

        // Act
        batcher.add('item1');
        batcher.add('item2');
        batcher.dispose(); // Should flush remaining items

        // Assert
        expect(processedItems, containsAll(['item1', 'item2']));
      });
    });

    group('IntervalRateLimiter Resource Cleanup', () {
      test('should cancel pending execution when dispose is called', () async {
        // Arrange
        final rateLimiter = IntervalRateLimiter(
          minInterval: const Duration(milliseconds: 100),
        );
        bool actionExecuted = false;

        // Execute once to set up the interval
        await rateLimiter.execute(() async {});

        // Act
        final _ = rateLimiter.execute(() async {
          actionExecuted = true;
        });
        rateLimiter.dispose(); // Should cancel pending execution

        // Wait for potential execution
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        expect(actionExecuted, isFalse);
      });
    });

    group('Throttler Resource Cleanup', () {
      test('should reset state when reset is called', () {
        // Arrange
        final throttler = Throttler(
          duration: const Duration(milliseconds: 100),
        );
        bool firstActionExecuted = false;
        bool secondActionExecuted = false;

        // Act
        final firstResult = throttler.call(() => firstActionExecuted = true);
        throttler.reset();
        final secondResult = throttler.call(() => secondActionExecuted = true);

        // Assert
        expect(firstResult, isTrue);
        expect(secondResult, isTrue);
        expect(firstActionExecuted, isTrue);
        expect(secondActionExecuted, isTrue);
      });
    });

    group('Stream Controller Cleanup', () {
      test('should close stream controller properly', () async {
        // Arrange
        final controller = StreamController<String>.broadcast();
        bool listenerCalled = false;

        final subscription = controller.stream.listen((_) {
          listenerCalled = true;
        });

        // Act
        await controller.close();

        // Try to add data after closing
        try {
          controller.add('test');
        } catch (e) {
          // Expected to throw
        }

        // Assert
        expect(controller.isClosed, isTrue);
        expect(listenerCalled, isFalse);

        // Clean up
        await subscription.cancel();
      });
    });

    group('Timer Resource Cleanup', () {
      test('should cancel timer properly', () async {
        // Arrange
        bool timerExecuted = false;
        final timer = Timer(const Duration(milliseconds: 100), () {
          timerExecuted = true;
        });

        // Act
        timer.cancel();

        // Wait longer than the timer duration
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        expect(timerExecuted, isFalse);
        expect(timer.isActive, isFalse);
      });

      test('should handle periodic timer cancellation', () async {
        // Arrange
        int executionCount = 0;
        final timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
          executionCount++;
        });

        // Let it execute a few times
        await Future.delayed(const Duration(milliseconds: 120));

        // Act
        timer.cancel();
        final countAfterCancel = executionCount;

        // Wait more time
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(timer.isActive, isFalse);
        expect(executionCount, equals(countAfterCancel)); // Should not increase
      });
    });

    group('Multiple Resource Cleanup', () {
      test(
        'should handle cleanup of multiple resources simultaneously',
        () async {
          // Arrange
          final debouncer = Debouncer(delay: const Duration(milliseconds: 100));
          final batcher = Batcher<String>(
            delay: const Duration(milliseconds: 100),
            onBatch: (_) {},
          );
          final controller = StreamController<String>.broadcast();
          final timer = Timer(const Duration(milliseconds: 100), () {});

          // Act - cleanup all resources
          debouncer.dispose();
          batcher.dispose();
          timer.cancel();
          await controller.close();

          // Assert - all should be cleaned up without errors
          expect(timer.isActive, isFalse);
          expect(controller.isClosed, isTrue);
        },
      );
    });
  });
}
