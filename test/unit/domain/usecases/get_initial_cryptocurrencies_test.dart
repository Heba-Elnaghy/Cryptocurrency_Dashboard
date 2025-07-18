import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:crypto_dashboard/domain/entities/entities.dart';
import 'package:crypto_dashboard/domain/repositories/cryptocurrency_repository.dart';
import 'package:crypto_dashboard/domain/usecases/get_initial_cryptocurrencies.dart';

import 'get_initial_cryptocurrencies_test.mocks.dart';

@GenerateMocks([CryptocurrencyRepository])
void main() {
  group('GetInitialCryptocurrencies Use Case', () {
    late GetInitialCryptocurrencies useCase;
    late MockCryptocurrencyRepository mockRepository;
    late DateTime testDateTime;

    setUp(() {
      mockRepository = MockCryptocurrencyRepository();
      useCase = GetInitialCryptocurrencies(mockRepository);
      testDateTime = DateTime(2024, 1, 1, 12, 0, 0);
    });

    group('Required Symbols', () {
      test('should have correct required symbols list', () {
        // Assert
        expect(GetInitialCryptocurrencies.requiredSymbols, hasLength(10));
        expect(GetInitialCryptocurrencies.requiredSymbols, contains('BTC'));
        expect(GetInitialCryptocurrencies.requiredSymbols, contains('ETH'));
        expect(GetInitialCryptocurrencies.requiredSymbols, contains('XRP'));
        expect(GetInitialCryptocurrencies.requiredSymbols, contains('BNB'));
        expect(GetInitialCryptocurrencies.requiredSymbols, contains('SOL'));
        expect(GetInitialCryptocurrencies.requiredSymbols, contains('DOGE'));
        expect(GetInitialCryptocurrencies.requiredSymbols, contains('TRX'));
        expect(GetInitialCryptocurrencies.requiredSymbols, contains('ADA'));
        expect(GetInitialCryptocurrencies.requiredSymbols, contains('AVAX'));
        expect(GetInitialCryptocurrencies.requiredSymbols, contains('XLM'));
      });

      test('should maintain required symbols order', () {
        // Assert - Order matters for consistent display
        final expectedOrder = [
          'BTC',
          'ETH',
          'XRP',
          'BNB',
          'SOL',
          'DOGE',
          'TRX',
          'ADA',
          'AVAX',
          'XLM',
        ];
        expect(
          GetInitialCryptocurrencies.requiredSymbols,
          equals(expectedOrder),
        );
      });
    });

    group('Successful Execution', () {
      test(
        'should return ordered list of cryptocurrencies when all required symbols present',
        () async {
          // Arrange
          final mockCryptocurrencies = _createMockCryptocurrencies();
          when(
            mockRepository.getInitialCryptocurrencies(),
          ).thenAnswer((_) async => mockCryptocurrencies);

          // Act
          final result = await useCase.call();

          // Assert
          expect(result, hasLength(10));
          expect(result[0].symbol, equals('BTC'));
          expect(result[1].symbol, equals('ETH'));
          expect(result[2].symbol, equals('XRP'));
          expect(result[9].symbol, equals('XLM'));
          verify(mockRepository.getInitialCryptocurrencies()).called(1);
        },
      );

      test('should filter and order cryptocurrencies correctly', () async {
        // Arrange - Include extra cryptocurrencies that should be filtered out
        final mockCryptocurrencies = [
          ..._createMockCryptocurrencies(),
          Cryptocurrency(
            symbol: 'EXTRA1',
            name: 'Extra Coin 1',
            price: 1.0,
            priceChange24h: 0.0,
            volume24h: 1000.0,
            status: ListingStatus.active,
            lastUpdated: testDateTime,
          ),
          Cryptocurrency(
            symbol: 'EXTRA2',
            name: 'Extra Coin 2',
            price: 2.0,
            priceChange24h: 0.0,
            volume24h: 2000.0,
            status: ListingStatus.active,
            lastUpdated: testDateTime,
          ),
        ];

        when(
          mockRepository.getInitialCryptocurrencies(),
        ).thenAnswer((_) async => mockCryptocurrencies);

        // Act
        final result = await useCase.call();

        // Assert - Should only return the 10 required cryptocurrencies in correct order
        expect(result, hasLength(10));
        expect(
          result.map((c) => c.symbol).toList(),
          equals(GetInitialCryptocurrencies.requiredSymbols),
        );
        expect(result.any((c) => c.symbol == 'EXTRA1'), isFalse);
        expect(result.any((c) => c.symbol == 'EXTRA2'), isFalse);
      });

      test(
        'should handle cryptocurrencies returned in different order',
        () async {
          // Arrange - Return cryptocurrencies in reverse order
          final mockCryptocurrencies = _createMockCryptocurrencies().reversed
              .toList();
          when(
            mockRepository.getInitialCryptocurrencies(),
          ).thenAnswer((_) async => mockCryptocurrencies);

          // Act
          final result = await useCase.call();

          // Assert - Should still return in correct order
          expect(result, hasLength(10));
          expect(result[0].symbol, equals('BTC'));
          expect(result[1].symbol, equals('ETH'));
          expect(result[9].symbol, equals('XLM'));
        },
      );
    });

    group('Error Handling', () {
      test(
        'should throw GetInitialCryptocurrenciesException when repository throws',
        () async {
          // Arrange
          when(
            mockRepository.getInitialCryptocurrencies(),
          ).thenThrow(Exception('Network error'));

          // Act & Assert
          expect(
            () => useCase.call(),
            throwsA(
              isA<GetInitialCryptocurrenciesException>()
                  .having(
                    (e) => e.errorType,
                    'errorType',
                    GetInitialCryptocurrenciesErrorType.apiError,
                  )
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Failed to fetch initial cryptocurrencies'),
                  )
                  .having(
                    (e) => e.originalException,
                    'originalException',
                    isNotNull,
                  ),
            ),
          );
        },
      );

      test(
        'should throw GetInitialCryptocurrenciesException when no data received',
        () async {
          // Arrange
          when(
            mockRepository.getInitialCryptocurrencies(),
          ).thenAnswer((_) async => []);

          // Act & Assert
          expect(
            () => useCase.call(),
            throwsA(
              isA<GetInitialCryptocurrenciesException>()
                  .having(
                    (e) => e.errorType,
                    'errorType',
                    GetInitialCryptocurrenciesErrorType.noData,
                  )
                  .having(
                    (e) => e.message,
                    'message',
                    equals('No cryptocurrency data received from API'),
                  ),
            ),
          );
        },
      );

      test(
        'should throw GetInitialCryptocurrenciesException when required symbols missing',
        () async {
          // Arrange - Missing BTC and ETH
          final incompleteCryptocurrencies = [
            Cryptocurrency(
              symbol: 'XRP',
              name: 'XRP',
              price: 0.5,
              priceChange24h: 0.01,
              volume24h: 100000.0,
              status: ListingStatus.active,
              lastUpdated: testDateTime,
            ),
            Cryptocurrency(
              symbol: 'BNB',
              name: 'Binance Coin',
              price: 300.0,
              priceChange24h: 5.0,
              volume24h: 50000.0,
              status: ListingStatus.active,
              lastUpdated: testDateTime,
            ),
          ];

          when(
            mockRepository.getInitialCryptocurrencies(),
          ).thenAnswer((_) async => incompleteCryptocurrencies);

          // Act & Assert
          expect(
            () => useCase.call(),
            throwsA(
              isA<GetInitialCryptocurrenciesException>()
                  .having(
                    (e) => e.errorType,
                    'errorType',
                    GetInitialCryptocurrenciesErrorType.missingSymbols,
                  )
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Missing required cryptocurrency symbols'),
                  )
                  .having(
                    (e) => e.missingSymbols,
                    'missingSymbols',
                    containsAll(['BTC', 'ETH']),
                  ),
            ),
          );
        },
      );

      test(
        'should throw GetInitialCryptocurrenciesException when single required symbol missing',
        () async {
          // Arrange - Missing only BTC
          final mockCryptocurrencies = _createMockCryptocurrencies()
              .where((crypto) => crypto.symbol != 'BTC')
              .toList();

          when(
            mockRepository.getInitialCryptocurrencies(),
          ).thenAnswer((_) async => mockCryptocurrencies);

          // Act & Assert
          expect(
            () => useCase.call(),
            throwsA(
              isA<GetInitialCryptocurrenciesException>()
                  .having(
                    (e) => e.errorType,
                    'errorType',
                    GetInitialCryptocurrenciesErrorType.missingSymbols,
                  )
                  .having(
                    (e) => e.message,
                    'message',
                    contains('Missing required cryptocurrency symbols: BTC'),
                  )
                  .having(
                    (e) => e.missingSymbols,
                    'missingSymbols',
                    equals(['BTC']),
                  ),
            ),
          );
        },
      );

      test(
        'should rethrow GetInitialCryptocurrenciesException without wrapping',
        () async {
          // Arrange
          final originalException = GetInitialCryptocurrenciesException(
            'Original error',
            GetInitialCryptocurrenciesErrorType.validationError,
          );

          when(
            mockRepository.getInitialCryptocurrencies(),
          ).thenThrow(originalException);

          // Act & Assert
          expect(() => useCase.call(), throwsA(same(originalException)));
        },
      );
    });

    group('Validation Logic', () {
      test(
        'should validate all required symbols are present in response',
        () async {
          // Arrange - Create list with all required symbols
          final mockCryptocurrencies = _createMockCryptocurrencies();
          when(
            mockRepository.getInitialCryptocurrencies(),
          ).thenAnswer((_) async => mockCryptocurrencies);

          // Act
          final result = await useCase.call();

          // Assert - Verify all required symbols are present
          final resultSymbols = result.map((c) => c.symbol).toSet();
          final requiredSymbols = GetInitialCryptocurrencies.requiredSymbols
              .toSet();
          expect(resultSymbols, equals(requiredSymbols));
        },
      );

      test('should handle duplicate symbols in repository response', () async {
        // Arrange - Include duplicate BTC
        final mockCryptocurrencies = [
          ..._createMockCryptocurrencies(),
          Cryptocurrency(
            symbol: 'BTC',
            name: 'Bitcoin Duplicate',
            price: 51000.0,
            priceChange24h: 1000.0,
            volume24h: 2000000.0,
            status: ListingStatus.active,
            lastUpdated: testDateTime,
          ),
        ];

        when(
          mockRepository.getInitialCryptocurrencies(),
        ).thenAnswer((_) async => mockCryptocurrencies);

        // Act
        final result = await useCase.call();

        // Assert - Should return only one BTC (first one found)
        expect(result, hasLength(10));
        final btcEntries = result.where((c) => c.symbol == 'BTC').toList();
        expect(btcEntries, hasLength(1));
        expect(
          btcEntries.first.name,
          equals('Bitcoin'),
        ); // First one, not duplicate
      });
    });

    group('Exception Details', () {
      test('should create exception with correct properties for API error', () {
        // Arrange
        const originalError = 'Network timeout';
        final exception = GetInitialCryptocurrenciesException(
          'Failed to fetch: $originalError',
          GetInitialCryptocurrenciesErrorType.apiError,
          originalException: originalError,
        );

        // Assert
        expect(exception.message, equals('Failed to fetch: $originalError'));
        expect(
          exception.errorType,
          equals(GetInitialCryptocurrenciesErrorType.apiError),
        );
        expect(exception.originalException, equals(originalError));
        expect(exception.missingSymbols, isNull);
        expect(
          exception.toString(),
          contains('GetInitialCryptocurrenciesException'),
        );
      });

      test('should create exception with missing symbols details', () {
        // Arrange
        final missingSymbols = ['BTC', 'ETH'];
        final exception = GetInitialCryptocurrenciesException(
          'Missing symbols',
          GetInitialCryptocurrenciesErrorType.missingSymbols,
          missingSymbols: missingSymbols,
        );

        // Assert
        expect(
          exception.errorType,
          equals(GetInitialCryptocurrenciesErrorType.missingSymbols),
        );
        expect(exception.missingSymbols, equals(missingSymbols));
        expect(exception.originalException, isNull);
      });
    });

    group('Integration Scenarios', () {
      test('should handle mixed listing statuses correctly', () async {
        // Arrange - Mix of active and delisted cryptocurrencies
        final mockCryptocurrencies = _createMockCryptocurrencies();
        mockCryptocurrencies[1] = mockCryptocurrencies[1].copyWith(
          status: ListingStatus.delisted,
        );

        when(
          mockRepository.getInitialCryptocurrencies(),
        ).thenAnswer((_) async => mockCryptocurrencies);

        // Act
        final result = await useCase.call();

        // Assert - Should include delisted cryptocurrencies
        expect(result, hasLength(10));
        expect(result[1].status, equals(ListingStatus.delisted));
        expect(result[1].symbol, equals('ETH'));
      });

      test('should preserve all cryptocurrency properties', () async {
        // Arrange
        final mockCryptocurrencies = _createMockCryptocurrencies();
        when(
          mockRepository.getInitialCryptocurrencies(),
        ).thenAnswer((_) async => mockCryptocurrencies);

        // Act
        final result = await useCase.call();

        // Assert - Verify all properties are preserved
        final btc = result.firstWhere((c) => c.symbol == 'BTC');
        expect(btc.name, equals('Bitcoin'));
        expect(btc.price, equals(50000.0));
        expect(btc.priceChange24h, equals(1500.0));
        expect(btc.volume24h, equals(1000000.0));
        expect(btc.status, equals(ListingStatus.active));
        expect(btc.lastUpdated, equals(testDateTime));
        expect(btc.hasVolumeSpike, isFalse);
      });
    });
  });
}

/// Helper method to create mock cryptocurrencies for testing
List<Cryptocurrency> _createMockCryptocurrencies() {
  final testDateTime = DateTime(2024, 1, 1, 12, 0, 0);

  return [
    Cryptocurrency(
      symbol: 'BTC',
      name: 'Bitcoin',
      price: 50000.0,
      priceChange24h: 1500.0,
      volume24h: 1000000.0,
      status: ListingStatus.active,
      lastUpdated: testDateTime,
    ),
    Cryptocurrency(
      symbol: 'ETH',
      name: 'Ethereum',
      price: 3000.0,
      priceChange24h: -100.0,
      volume24h: 500000.0,
      status: ListingStatus.active,
      lastUpdated: testDateTime,
    ),
    Cryptocurrency(
      symbol: 'XRP',
      name: 'XRP',
      price: 0.5,
      priceChange24h: 0.01,
      volume24h: 100000.0,
      status: ListingStatus.active,
      lastUpdated: testDateTime,
    ),
    Cryptocurrency(
      symbol: 'BNB',
      name: 'Binance Coin',
      price: 300.0,
      priceChange24h: 5.0,
      volume24h: 50000.0,
      status: ListingStatus.active,
      lastUpdated: testDateTime,
    ),
    Cryptocurrency(
      symbol: 'SOL',
      name: 'Solana',
      price: 100.0,
      priceChange24h: 2.0,
      volume24h: 75000.0,
      status: ListingStatus.active,
      lastUpdated: testDateTime,
    ),
    Cryptocurrency(
      symbol: 'DOGE',
      name: 'Dogecoin',
      price: 0.08,
      priceChange24h: 0.002,
      volume24h: 200000.0,
      status: ListingStatus.active,
      lastUpdated: testDateTime,
    ),
    Cryptocurrency(
      symbol: 'TRX',
      name: 'TRON',
      price: 0.1,
      priceChange24h: 0.005,
      volume24h: 80000.0,
      status: ListingStatus.active,
      lastUpdated: testDateTime,
    ),
    Cryptocurrency(
      symbol: 'ADA',
      name: 'Cardano',
      price: 0.4,
      priceChange24h: 0.02,
      volume24h: 60000.0,
      status: ListingStatus.active,
      lastUpdated: testDateTime,
    ),
    Cryptocurrency(
      symbol: 'AVAX',
      name: 'Avalanche',
      price: 25.0,
      priceChange24h: 1.0,
      volume24h: 30000.0,
      status: ListingStatus.active,
      lastUpdated: testDateTime,
    ),
    Cryptocurrency(
      symbol: 'XLM',
      name: 'Stellar',
      price: 0.12,
      priceChange24h: 0.003,
      volume24h: 40000.0,
      status: ListingStatus.active,
      lastUpdated: testDateTime,
    ),
  ];
}
