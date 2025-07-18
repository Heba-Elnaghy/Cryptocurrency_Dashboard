import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:crypto_dashboard/data/repositories/cryptocurrency_repository_impl.dart';
import 'package:crypto_dashboard/data/datasources/okx_api_service.dart';
import 'package:crypto_dashboard/data/models/models.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';
import 'package:crypto_dashboard/core/network/network.dart';
import 'package:crypto_dashboard/core/error/error_handling.dart';

import 'cryptocurrency_repository_impl_test.mocks.dart';

@GenerateMocks([OKXApiService, NetworkErrorHandler, OfflineManager])
void main() {
  group('CryptocurrencyRepositoryImpl', () {
    late CryptocurrencyRepositoryImpl repository;
    late MockOKXApiService mockApiService;
    late MockNetworkErrorHandler mockNetworkErrorHandler;
    late MockOfflineManager mockOfflineManager;

    // Test data
    late OKXInstrumentResponse mockInstrumentResponse;
    late OKXTickerResponse mockTickerResponse;

    setUp(() {
      mockApiService = MockOKXApiService();
      mockNetworkErrorHandler = MockNetworkErrorHandler();
      mockOfflineManager = MockOfflineManager();

      repository = CryptocurrencyRepositoryImpl(
        mockApiService,
        mockNetworkErrorHandler,
        mockOfflineManager,
      );

      // Setup test data
      mockInstrumentResponse = OKXInstrumentResponse(
        code: '0',
        msg: '',
        data: [
          const OKXInstrument(
            instId: 'BTC-USDT',
            baseCcy: 'BTC',
            quoteCcy: 'USDT',
            state: 'live',
            instType: 'SPOT',
          ),
          const OKXInstrument(
            instId: 'ETH-USDT',
            baseCcy: 'ETH',
            quoteCcy: 'USDT',
            state: 'live',
            instType: 'SPOT',
          ),
        ],
      );

      mockTickerResponse = OKXTickerResponse(
        code: '0',
        msg: '',
        data: [
          const OKXTicker(
            instId: 'BTC-USDT',
            last: '50000.0',
            vol24h: '1000000.0',
            volCcy24h: '50000000000.0',
            open24h: '49000.0',
            high24h: '51000.0',
            low24h: '48000.0',
            ts: '1640995200000',
          ),
          const OKXTicker(
            instId: 'ETH-USDT',
            last: '3000.0',
            vol24h: '500000.0',
            volCcy24h: '1500000000.0',
            open24h: '2950.0',
            high24h: '3100.0',
            low24h: '2900.0',
            ts: '1640995200000',
          ),
        ],
      );
    });

    tearDown(() {
      repository.dispose();
    });

    group('getInitialCryptocurrencies', () {
      test('should return cryptocurrencies when API calls succeed', () async {
        // Arrange
        when(
          mockNetworkErrorHandler
              .executeWithEnhancedHandling<List<Cryptocurrency>>(
                any,
                config: anyNamed('config'),
                onEvent: anyNamed('onEvent'),
              ),
        ).thenAnswer((invocation) async {
          final operation =
              invocation.positionalArguments[0]
                  as Future<List<Cryptocurrency>> Function();
          final result = await operation();
          return NetworkOperationResult.success(result, 1, []);
        });

        when(
          mockApiService.getInstruments(),
        ).thenAnswer((_) async => mockInstrumentResponse);
        when(
          mockApiService.getSupportedCryptoTickers(),
        ).thenAnswer((_) async => mockTickerResponse);

        // Act
        final result = await repository.getInitialCryptocurrencies();

        // Assert
        expect(result, hasLength(2));
        expect(result[0].symbol, equals('BTC'));
        expect(result[1].symbol, equals('ETH'));
        expect(result[0].price, equals(50000.0));
        expect(result[1].price, equals(3000.0));

        verify(mockApiService.getInstruments()).called(1);
        verify(mockApiService.getSupportedCryptoTickers()).called(1);
      });

      test(
        'should throw DataFailure when no required cryptocurrencies found',
        () async {
          // Arrange
          final emptyInstrumentResponse = OKXInstrumentResponse(
            code: '0',
            msg: '',
            data: [],
          );

          when(
            mockNetworkErrorHandler
                .executeWithEnhancedHandling<List<Cryptocurrency>>(
                  any,
                  config: anyNamed('config'),
                  onEvent: anyNamed('onEvent'),
                ),
          ).thenAnswer((invocation) async {
            final operation =
                invocation.positionalArguments[0]
                    as Future<List<Cryptocurrency>> Function();
            try {
              await operation();
              return NetworkOperationResult.failure(
                const DataFailure(
                  message: 'No required cryptocurrencies found',
                  details:
                      'API response did not contain the required cryptocurrency symbols',
                ),
                1,
                [],
              );
            } catch (e) {
              return NetworkOperationResult.failure(e as Failure, 1, []);
            }
          });

          when(
            mockApiService.getInstruments(),
          ).thenAnswer((_) async => emptyInstrumentResponse);
          when(
            mockApiService.getSupportedCryptoTickers(),
          ).thenAnswer((_) async => mockTickerResponse);

          // Act & Assert
          expect(
            () => repository.getInitialCryptocurrencies(),
            throwsA(isA<DataFailure>()),
          );
        },
      );

      test('should handle network failures appropriately', () async {
        // Arrange
        const networkFailure = NetworkFailure(
          message: 'Network error',
          details: 'Connection timeout',
        );

        when(
          mockNetworkErrorHandler
              .executeWithEnhancedHandling<List<Cryptocurrency>>(
                any,
                config: anyNamed('config'),
                onEvent: anyNamed('onEvent'),
              ),
        ).thenAnswer(
          (_) async => NetworkOperationResult.failure(networkFailure, 1, []),
        );

        // Act & Assert
        expect(
          () => repository.getInitialCryptocurrencies(),
          throwsA(isA<NetworkFailure>()),
        );
      });
    });

    group('Real-time Updates', () {
      test('should start real-time updates successfully', () async {
        // Arrange
        when(
          mockApiService.getInstruments(),
        ).thenAnswer((_) async => mockInstrumentResponse);
        when(
          mockApiService.getSupportedCryptoTickers(),
        ).thenAnswer((_) async => mockTickerResponse);
        when(
          mockNetworkErrorHandler
              .executeWithEnhancedHandling<List<Cryptocurrency>>(
                any,
                config: anyNamed('config'),
                onEvent: anyNamed('onEvent'),
              ),
        ).thenAnswer((invocation) async {
          final operation =
              invocation.positionalArguments[0]
                  as Future<List<Cryptocurrency>> Function();
          final result = await operation();
          return NetworkOperationResult.success(result, 1, []);
        });

        // Initialize with some data first
        await repository.getInitialCryptocurrencies();

        // Act
        await repository.startRealTimeUpdates();

        // Assert
        expect(repository.isUpdating, isTrue);
      });

      test('should stop real-time updates successfully', () async {
        // Arrange
        when(
          mockApiService.getInstruments(),
        ).thenAnswer((_) async => mockInstrumentResponse);
        when(
          mockApiService.getSupportedCryptoTickers(),
        ).thenAnswer((_) async => mockTickerResponse);
        when(
          mockNetworkErrorHandler
              .executeWithEnhancedHandling<List<Cryptocurrency>>(
                any,
                config: anyNamed('config'),
                onEvent: anyNamed('onEvent'),
              ),
        ).thenAnswer((invocation) async {
          final operation =
              invocation.positionalArguments[0]
                  as Future<List<Cryptocurrency>> Function();
          final result = await operation();
          return NetworkOperationResult.success(result, 1, []);
        });

        await repository.getInitialCryptocurrencies();
        await repository.startRealTimeUpdates();

        // Act
        await repository.stopRealTimeUpdates();

        // Assert
        expect(repository.isUpdating, isFalse);
      });

      test('should not start updates if already updating', () async {
        // Arrange
        when(
          mockApiService.getInstruments(),
        ).thenAnswer((_) async => mockInstrumentResponse);
        when(
          mockApiService.getSupportedCryptoTickers(),
        ).thenAnswer((_) async => mockTickerResponse);
        when(
          mockNetworkErrorHandler
              .executeWithEnhancedHandling<List<Cryptocurrency>>(
                any,
                config: anyNamed('config'),
                onEvent: anyNamed('onEvent'),
              ),
        ).thenAnswer((invocation) async {
          final operation =
              invocation.positionalArguments[0]
                  as Future<List<Cryptocurrency>> Function();
          final result = await operation();
          return NetworkOperationResult.success(result, 1, []);
        });

        await repository.getInitialCryptocurrencies();
        await repository.startRealTimeUpdates();

        // Act
        await repository.startRealTimeUpdates(); // Second call

        // Assert
        expect(repository.isUpdating, isTrue);
      });

      test('should not stop updates if not updating', () async {
        // Act
        await repository.stopRealTimeUpdates();

        // Assert
        expect(repository.isUpdating, isFalse);
      });
    });

    group('Stream Setup', () {
      test('should provide price updates stream', () {
        expect(repository.getPriceUpdates(), isA<Stream<PriceUpdateEvent>>());
      });

      test('should provide volume alerts stream', () {
        expect(repository.getVolumeAlerts(), isA<Stream<VolumeAlert>>());
      });

      test('should provide connection status stream', () {
        expect(
          repository.getConnectionStatus(),
          isA<Stream<ConnectionStatus>>(),
        );
      });
    });

    group('Error Handling', () {
      test('should handle API service exceptions', () async {
        // Arrange
        when(
          mockNetworkErrorHandler
              .executeWithEnhancedHandling<List<Cryptocurrency>>(
                any,
                config: anyNamed('config'),
                onEvent: anyNamed('onEvent'),
              ),
        ).thenAnswer((invocation) async {
          final operation =
              invocation.positionalArguments[0]
                  as Future<List<Cryptocurrency>> Function();
          try {
            await operation();
          } catch (e) {
            return NetworkOperationResult.failure(e as Failure, 1, []);
          }
          return NetworkOperationResult.success([], 1, []);
        });

        when(
          mockApiService.getInstruments(),
        ).thenThrow(const NetworkFailure(message: 'Network error'));

        // Act & Assert
        expect(
          () => repository.getInitialCryptocurrencies(),
          throwsA(isA<NetworkFailure>()),
        );
      });

      test('should handle generic exceptions', () async {
        // Arrange
        when(
          mockNetworkErrorHandler
              .executeWithEnhancedHandling<List<Cryptocurrency>>(
                any,
                config: anyNamed('config'),
                onEvent: anyNamed('onEvent'),
              ),
        ).thenAnswer((invocation) async {
          final operation =
              invocation.positionalArguments[0]
                  as Future<List<Cryptocurrency>> Function();
          try {
            await operation();
          } catch (e) {
            final failure = ErrorHandler.handleException(e as Exception);
            return NetworkOperationResult.failure(failure, 1, []);
          }
          return NetworkOperationResult.success([], 1, []);
        });

        when(
          mockApiService.getInstruments(),
        ).thenThrow(Exception('Generic error'));

        // Act & Assert
        expect(
          () => repository.getInitialCryptocurrencies(),
          throwsA(isA<Failure>()),
        );
      });
    });

    group('Resource Management', () {
      test('should dispose resources properly', () {
        // Act
        repository.dispose();

        // Assert
        expect(repository.isUpdating, isFalse);
        verify(mockApiService.dispose()).called(1);
      });

      test('should handle multiple dispose calls', () {
        // Act
        repository.dispose();
        repository.dispose(); // Second call

        // Assert - Should not throw
        expect(repository.isUpdating, isFalse);
      });

      test('should stop updates when disposed', () async {
        // Arrange
        when(
          mockApiService.getInstruments(),
        ).thenAnswer((_) async => mockInstrumentResponse);
        when(
          mockApiService.getSupportedCryptoTickers(),
        ).thenAnswer((_) async => mockTickerResponse);
        when(
          mockNetworkErrorHandler
              .executeWithEnhancedHandling<List<Cryptocurrency>>(
                any,
                config: anyNamed('config'),
                onEvent: anyNamed('onEvent'),
              ),
        ).thenAnswer((invocation) async {
          final operation =
              invocation.positionalArguments[0]
                  as Future<List<Cryptocurrency>> Function();
          final result = await operation();
          return NetworkOperationResult.success(result, 1, []);
        });

        await repository.getInitialCryptocurrencies();
        await repository.startRealTimeUpdates();

        // Act
        repository.dispose();

        // Assert
        expect(repository.isUpdating, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle empty API responses', () async {
        // Arrange
        final emptyInstrumentResponse = OKXInstrumentResponse(
          code: '0',
          msg: '',
          data: [],
        );
        final emptyTickerResponse = OKXTickerResponse(
          code: '0',
          msg: '',
          data: [],
        );

        when(
          mockNetworkErrorHandler
              .executeWithEnhancedHandling<List<Cryptocurrency>>(
                any,
                config: anyNamed('config'),
                onEvent: anyNamed('onEvent'),
              ),
        ).thenAnswer((invocation) async {
          final operation =
              invocation.positionalArguments[0]
                  as Future<List<Cryptocurrency>> Function();
          try {
            await operation();
            return NetworkOperationResult.failure(
              const DataFailure(
                message: 'No required cryptocurrencies found',
                details:
                    'API response did not contain the required cryptocurrency symbols',
              ),
              1,
              [],
            );
          } catch (e) {
            return NetworkOperationResult.failure(e as Failure, 1, []);
          }
        });

        when(
          mockApiService.getInstruments(),
        ).thenAnswer((_) async => emptyInstrumentResponse);
        when(
          mockApiService.getSupportedCryptoTickers(),
        ).thenAnswer((_) async => emptyTickerResponse);

        // Act & Assert
        expect(
          () => repository.getInitialCryptocurrencies(),
          throwsA(isA<DataFailure>()),
        );
      });

      test('should handle malformed API responses', () async {
        // Arrange
        when(
          mockNetworkErrorHandler
              .executeWithEnhancedHandling<List<Cryptocurrency>>(
                any,
                config: anyNamed('config'),
                onEvent: anyNamed('onEvent'),
              ),
        ).thenAnswer((invocation) async {
          final operation =
              invocation.positionalArguments[0]
                  as Future<List<Cryptocurrency>> Function();
          try {
            await operation();
          } catch (e) {
            return NetworkOperationResult.failure(e as Failure, 1, []);
          }
          return NetworkOperationResult.success([], 1, []);
        });

        when(
          mockApiService.getInstruments(),
        ).thenThrow(const DataFailure(message: 'Malformed response'));

        // Act & Assert
        expect(
          () => repository.getInitialCryptocurrencies(),
          throwsA(isA<DataFailure>()),
        );
      });
    });
  });
}
