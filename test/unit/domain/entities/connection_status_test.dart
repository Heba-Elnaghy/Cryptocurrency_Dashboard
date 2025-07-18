import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';

void main() {
  group('ConnectionStatus Entity', () {
    late DateTime testDateTime;

    setUp(() {
      testDateTime = DateTime(2024, 1, 1, 12, 0, 0);
    });

    group('Constructor', () {
      test('should create connection status with all required properties', () {
        // Arrange & Act
        final connectionStatus = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );

        // Assert
        expect(connectionStatus.isConnected, isTrue);
        expect(connectionStatus.statusMessage, equals('Connected'));
        expect(connectionStatus.lastUpdate, equals(testDateTime));
      });

      test('should create disconnected status', () {
        // Arrange & Act
        final connectionStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Disconnected',
          lastUpdate: testDateTime,
        );

        // Assert
        expect(connectionStatus.isConnected, isFalse);
        expect(connectionStatus.statusMessage, equals('Disconnected'));
        expect(connectionStatus.lastUpdate, equals(testDateTime));
      });

      test('should create connecting status', () {
        // Arrange & Act
        final connectionStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Connecting...',
          lastUpdate: testDateTime,
        );

        // Assert
        expect(connectionStatus.isConnected, isFalse);
        expect(connectionStatus.statusMessage, equals('Connecting...'));
        expect(connectionStatus.lastUpdate, equals(testDateTime));
      });
    });

    group('copyWith', () {
      late ConnectionStatus originalStatus;

      setUp(() {
        originalStatus = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );
      });

      test('should return new instance with updated connection state', () {
        // Arrange & Act
        final updatedStatus = originalStatus.copyWith(isConnected: false);

        // Assert
        expect(updatedStatus.isConnected, isFalse);
        expect(
          updatedStatus.statusMessage,
          equals(originalStatus.statusMessage),
        );
        expect(updatedStatus.lastUpdate, equals(originalStatus.lastUpdate));
      });

      test('should return new instance with updated status message', () {
        // Arrange
        const newMessage = 'Reconnecting...';

        // Act
        final updatedStatus = originalStatus.copyWith(
          statusMessage: newMessage,
        );

        // Assert
        expect(updatedStatus.statusMessage, equals(newMessage));
        expect(updatedStatus.isConnected, equals(originalStatus.isConnected));
        expect(updatedStatus.lastUpdate, equals(originalStatus.lastUpdate));
      });

      test('should return new instance with updated timestamp', () {
        // Arrange
        final newTimestamp = DateTime(2024, 1, 2, 12, 0, 0);

        // Act
        final updatedStatus = originalStatus.copyWith(lastUpdate: newTimestamp);

        // Assert
        expect(updatedStatus.lastUpdate, equals(newTimestamp));
        expect(updatedStatus.isConnected, equals(originalStatus.isConnected));
        expect(
          updatedStatus.statusMessage,
          equals(originalStatus.statusMessage),
        );
      });

      test('should return new instance with all properties updated', () {
        // Arrange
        const newMessage = 'Connection failed';
        final newTimestamp = DateTime(2024, 1, 2, 12, 0, 0);

        // Act
        final updatedStatus = originalStatus.copyWith(
          isConnected: false,
          statusMessage: newMessage,
          lastUpdate: newTimestamp,
        );

        // Assert
        expect(updatedStatus.isConnected, isFalse);
        expect(updatedStatus.statusMessage, equals(newMessage));
        expect(updatedStatus.lastUpdate, equals(newTimestamp));
      });

      test('should return identical instance when no parameters provided', () {
        // Act
        final copiedStatus = originalStatus.copyWith();

        // Assert
        expect(copiedStatus.isConnected, equals(originalStatus.isConnected));
        expect(
          copiedStatus.statusMessage,
          equals(originalStatus.statusMessage),
        );
        expect(copiedStatus.lastUpdate, equals(originalStatus.lastUpdate));
      });
    });

    group('Equality', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final status1 = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );

        final status2 = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );

        // Act & Assert
        expect(status1, equals(status2));
        expect(status1.hashCode, equals(status2.hashCode));
      });

      test('should not be equal when isConnected differs', () {
        // Arrange
        final status1 = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );

        final status2 = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );

        // Act & Assert
        expect(status1, isNot(equals(status2)));
      });

      test('should not be equal when statusMessage differs', () {
        // Arrange
        final status1 = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );

        final status2 = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connecting...',
          lastUpdate: testDateTime,
        );

        // Act & Assert
        expect(status1, isNot(equals(status2)));
      });

      test('should not be equal when lastUpdate differs', () {
        // Arrange
        final status1 = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime,
        );

        final status2 = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime.add(const Duration(minutes: 1)),
        );

        // Act & Assert
        expect(status1, isNot(equals(status2)));
      });
    });

    group('Business Logic Scenarios', () {
      test('should represent successful connection state', () {
        // Arrange & Act
        final connectionStatus = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Live',
          lastUpdate: testDateTime,
        );

        // Assert - Connected state
        expect(connectionStatus.isConnected, isTrue);
        expect(connectionStatus.statusMessage, equals('Live'));
      });

      test('should represent connection attempt state', () {
        // Arrange & Act
        final connectionStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Connecting...',
          lastUpdate: testDateTime,
        );

        // Assert - Connecting state
        expect(connectionStatus.isConnected, isFalse);
        expect(connectionStatus.statusMessage, contains('Connecting'));
      });

      test('should represent reconnection attempt state', () {
        // Arrange & Act
        final connectionStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Reconnecting... (attempt 2/5)',
          lastUpdate: testDateTime,
        );

        // Assert - Reconnecting state
        expect(connectionStatus.isConnected, isFalse);
        expect(connectionStatus.statusMessage, contains('Reconnecting'));
        expect(connectionStatus.statusMessage, contains('attempt'));
      });

      test('should represent connection failure state', () {
        // Arrange & Act
        final connectionStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Connection failed after 5 attempts',
          lastUpdate: testDateTime,
        );

        // Assert - Failed state
        expect(connectionStatus.isConnected, isFalse);
        expect(connectionStatus.statusMessage, contains('failed'));
      });

      test('should represent retry waiting state', () {
        // Arrange & Act
        final connectionStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Retrying in 4s... (attempt 3/5)',
          lastUpdate: testDateTime,
        );

        // Assert - Waiting state
        expect(connectionStatus.isConnected, isFalse);
        expect(connectionStatus.statusMessage, contains('Retrying'));
        expect(connectionStatus.statusMessage, contains('s...'));
      });
    });

    group('Edge Cases', () {
      test('should handle empty status message', () {
        // Arrange & Act
        final connectionStatus = ConnectionStatus(
          isConnected: true,
          statusMessage: '',
          lastUpdate: testDateTime,
        );

        // Assert
        expect(connectionStatus.statusMessage, equals(''));
        expect(connectionStatus.isConnected, isTrue);
      });

      test('should handle very long status message', () {
        // Arrange
        const longMessage =
            'This is a very long status message that might occur '
            'in some edge cases where detailed error information is provided '
            'to help with debugging connection issues in the application';

        // Act
        final connectionStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: longMessage,
          lastUpdate: testDateTime,
        );

        // Assert
        expect(connectionStatus.statusMessage, equals(longMessage));
        expect(connectionStatus.statusMessage.length, greaterThan(100));
      });

      test('should handle special characters in status message', () {
        // Arrange
        const specialMessage =
            'Connection failed: 🔌 Network error (timeout: 30s) - retry #3';

        // Act
        final connectionStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: specialMessage,
          lastUpdate: testDateTime,
        );

        // Assert
        expect(connectionStatus.statusMessage, equals(specialMessage));
        expect(connectionStatus.statusMessage, contains('🔌'));
      });

      test('should handle future timestamp', () {
        // Arrange
        final futureTimestamp = DateTime.now().add(const Duration(hours: 1));

        // Act
        final connectionStatus = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: futureTimestamp,
        );

        // Assert
        expect(connectionStatus.lastUpdate, equals(futureTimestamp));
        expect(connectionStatus.lastUpdate.isAfter(DateTime.now()), isTrue);
      });

      test('should handle very old timestamp', () {
        // Arrange
        final oldTimestamp = DateTime(2020, 1, 1);

        // Act
        final connectionStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Last seen long ago',
          lastUpdate: oldTimestamp,
        );

        // Assert
        expect(connectionStatus.lastUpdate, equals(oldTimestamp));
        expect(
          connectionStatus.lastUpdate.isBefore(DateTime(2023, 1, 1)),
          isTrue,
        );
      });
    });

    group('State Transitions', () {
      test('should transition from connecting to connected', () {
        // Arrange
        final connectingStatus = ConnectionStatus(
          isConnected: false,
          statusMessage: 'Connecting...',
          lastUpdate: testDateTime,
        );

        // Act
        final connectedStatus = connectingStatus.copyWith(
          isConnected: true,
          statusMessage: 'Connected',
          lastUpdate: testDateTime.add(const Duration(seconds: 5)),
        );

        // Assert
        expect(connectingStatus.isConnected, isFalse);
        expect(connectedStatus.isConnected, isTrue);
        expect(
          connectedStatus.lastUpdate.isAfter(connectingStatus.lastUpdate),
          isTrue,
        );
      });

      test('should transition from connected to disconnected', () {
        // Arrange
        final connectedStatus = ConnectionStatus(
          isConnected: true,
          statusMessage: 'Live',
          lastUpdate: testDateTime,
        );

        // Act
        final disconnectedStatus = connectedStatus.copyWith(
          isConnected: false,
          statusMessage: 'Connection lost',
          lastUpdate: testDateTime.add(const Duration(minutes: 1)),
        );

        // Assert
        expect(connectedStatus.isConnected, isTrue);
        expect(disconnectedStatus.isConnected, isFalse);
        expect(disconnectedStatus.statusMessage, equals('Connection lost'));
      });
    });
  });
}
