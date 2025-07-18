import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:crypto_dashboard/data/datasources/okx_api_service.dart';
import 'package:crypto_dashboard/core/network/network.dart';
import 'package:crypto_dashboard/core/error/error_handling.dart';

import 'okx_api_service_test.mocks.dart';

@GenerateMocks([NetworkInfo, NetworkClient, OfflineManager, OfflineDetector])
void main() {
  group('OKXApiService', () {
    late OKXApiService apiService;
    late MockNetworkInfo mockNetworkInfo;
    late MockNetworkClient mockNetworkClient;
    late MockOfflineManager mockOfflineManager;
    late MockOfflineDetector mockOfflineDetector;

    setUp(() {
      mockNetworkInfo = MockNetworkInfo();
      mockNetworkClient = MockNetworkClient();
      mockOfflineManager = MockOfflineManager();
      mockOfflineDetector = MockOfflineDetector();

      apiService = OKXApiService(
        networkInfo: mockNetworkInfo,
        networkClient: mockNetworkClient,
        offlineManager: mockOfflineManager,
        offlineDetector: mockOfflineDetector,
      );
    });

    group('getInstruments', () {
      test(
        'should return OKXInstrumentResponse when API call succeeds',
        () async {
          // Arrange
          final mockResponse = Response<Map<String, dynamic>>(
            data: {
              'code': '0',
              'msg': '',
              'data': [
                {
                  'instId': 'BTC-USDT',
                  'baseCcy': 'BTC',
                  'quoteCcy': 'USDT',
                  'state': 'live',
                  'instType': 'SPOT',
                },
                {
                  'instId': 'ETH-USDT',
                  'baseCcy': 'ETH',
                  'quoteCcy': 'USDT',
                  'state': 'live',
                  'instType': 'SPOT',
                },
              ],
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/api/v5/public/instruments'),
          );

          when(
            mockNetworkClient.get(
              '/api/v5/public/instruments',
              queryParameters: {'instType': 'SPOT'},
              config: NetworkClientConfig.api,
            ),
          ).thenAnswer((_) async => mockResponse);

          // Act
          final result = await apiService.getInstruments();

          // Assert
          expect(result.code, equals('0'));
          expect(result.data, hasLength(2));
          expect(result.data[0].instId, equals('BTC-USDT'));
          expect(result.data[1].instId, equals('ETH-USDT'));

          verify(
            mockNetworkClient.get(
              '/api/v5/public/instruments',
              queryParameters: {'instType': 'SPOT'},
              config: NetworkClientConfig.api,
            ),
          ).called(1);
        },
      );

      test('should handle empty response data', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'code': '0',
            'msg': 'Success',
            'data': <Map<String, dynamic>>[],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v5/public/instruments'),
        );

        when(
          mockNetworkClient.get(
            '/api/v5/public/instruments',
            queryParameters: {'instType': 'SPOT'},
            config: NetworkClientConfig.api,
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.getInstruments();

        // Assert
        expect(result.code, equals('0'));
        expect(result.data, isEmpty);
      });

      test(
        'should throw NetworkFailure when network client throws NetworkFailure',
        () async {
          // Arrange
          const failure = NetworkFailure(
            message: 'Network error',
            details: 'Connection timeout',
          );

          when(
            mockNetworkClient.get(
              '/api/v5/public/instruments',
              queryParameters: {'instType': 'SPOT'},
              config: NetworkClientConfig.api,
            ),
          ).thenThrow(failure);

          // Act & Assert
          expect(
            () => apiService.getInstruments(),
            throwsA(isA<NetworkFailure>()),
          );
        },
      );

      test('should handle and convert generic exceptions', () async {
        // Arrange
        when(
          mockNetworkClient.get(
            '/api/v5/public/instruments',
            queryParameters: {'instType': 'SPOT'},
            config: NetworkClientConfig.api,
          ),
        ).thenThrow(Exception('Generic error'));

        // Act & Assert
        expect(() => apiService.getInstruments(), throwsA(isA<Failure>()));
      });
    });

    group('getTickers', () {
      test('should return OKXTickerResponse when API call succeeds', () async {
        // Arrange
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'code': '0',
            'msg': '',
            'data': [
              {
                'instId': 'BTC-USDT',
                'last': '50000.0',
                'vol24h': '1000000.0',
                'volCcy24h': '50000000000.0',
                'open24h': '49000.0',
                'high24h': '51000.0',
                'low24h': '48000.0',
                'ts': '1640995200000',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v5/market/tickers'),
        );

        when(
          mockNetworkClient.get(
            '/api/v5/market/tickers',
            queryParameters: {'instType': 'SPOT'},
            config: NetworkClientConfig.api,
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.getTickers();

        // Assert
        expect(result.code, equals('0'));
        expect(result.data, hasLength(1));
        expect(result.data[0].instId, equals('BTC-USDT'));
        expect(result.data[0].last, equals('50000.0'));

        verify(
          mockNetworkClient.get(
            '/api/v5/market/tickers',
            queryParameters: {'instType': 'SPOT'},
            config: NetworkClientConfig.api,
          ),
        ).called(1);
      });
    });

    group('getTickersForInstruments', () {
      test('should return tickers for specific instruments', () async {
        // Arrange
        final instrumentIds = ['BTC-USDT', 'ETH-USDT'];
        final mockResponse = Response<Map<String, dynamic>>(
          data: {
            'code': '0',
            'msg': '',
            'data': [
              {
                'instId': 'BTC-USDT',
                'last': '50000.0',
                'vol24h': '1000000.0',
                'volCcy24h': '50000000000.0',
                'open24h': '49000.0',
                'high24h': '51000.0',
                'low24h': '48000.0',
                'ts': '1640995200000',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/api/v5/market/tickers'),
        );

        when(
          mockNetworkClient.get(
            '/api/v5/market/tickers',
            queryParameters: {
              'instType': 'SPOT',
              'instId': 'BTC-USDT,ETH-USDT',
            },
            config: NetworkClientConfig.realTime,
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.getTickersForInstruments(instrumentIds);

        // Assert
        expect(result.code, equals('0'));
        expect(result.data, hasLength(1));
        expect(result.data[0].instId, equals('BTC-USDT'));

        verify(
          mockNetworkClient.get(
            '/api/v5/market/tickers',
            queryParameters: {
              'instType': 'SPOT',
              'instId': 'BTC-USDT,ETH-USDT',
            },
            config: NetworkClientConfig.realTime,
          ),
        ).called(1);
      });

      test(
        'should throw DataFailure when instrument IDs list is empty',
        () async {
          // Act & Assert
          expect(
            () => apiService.getTickersForInstruments([]),
            throwsA(isA<DataFailure>()),
          );
        },
      );
    });

    group('Network Status Methods', () {
      test('should return connection info from network client', () async {
        // Arrange
        final expectedInfo = NetworkConnectionInfo(
          status: NetworkStatus.connected,
          quality: NetworkQuality.good,
          lastChecked: DateTime.now(),
        );

        when(
          mockNetworkClient.getConnectionInfo(),
        ).thenAnswer((_) async => expectedInfo);

        // Act
        final result = await apiService.getConnectionInfo();

        // Assert
        expect(result, equals(expectedInfo));
        verify(mockNetworkClient.getConnectionInfo()).called(1);
      });

      test('should return network availability from network client', () async {
        // Arrange
        when(
          mockNetworkClient.isNetworkAvailable,
        ).thenAnswer((_) async => true);

        // Act
        final result = await apiService.isNetworkAvailable;

        // Assert
        expect(result, isTrue);
      });

      test('should return offline status from offline manager', () {
        // Arrange
        when(mockOfflineManager.isOffline).thenReturn(true);

        // Act
        final result = apiService.isOffline;

        // Assert
        expect(result, isTrue);
        verify(mockOfflineManager.isOffline).called(1);
      });

      test('should handle null offline manager gracefully', () {
        // Arrange
        final serviceWithoutOfflineManager = OKXApiService(
          networkInfo: mockNetworkInfo,
          networkClient: mockNetworkClient,
        );

        // Act & Assert
        expect(serviceWithoutOfflineManager.isOffline, isFalse);
        expect(serviceWithoutOfflineManager.offlineDuration, isNull);
        expect(serviceWithoutOfflineManager.offlineMessage, equals(''));
      });
    });

    group('Resource Management', () {
      test('should dispose network client when dispose is called', () {
        // Act
        apiService.dispose();

        // Assert
        verify(mockNetworkClient.dispose()).called(1);
      });
    });

    group('Error Handling Edge Cases', () {
      test('should handle timeout errors appropriately', () async {
        // Arrange
        const failure = TimeoutFailure(
          message: 'Request timeout',
          details: 'Connection timed out after 30 seconds',
        );

        when(
          mockNetworkClient.get(
            '/api/v5/public/instruments',
            queryParameters: {'instType': 'SPOT'},
            config: NetworkClientConfig.api,
          ),
        ).thenThrow(failure);

        // Act & Assert
        expect(
          () => apiService.getInstruments(),
          throwsA(isA<TimeoutFailure>()),
        );
      });

      test('should handle connection errors appropriately', () async {
        // Arrange
        const failure = ConnectionFailure(
          message: 'Connection failed',
          details: 'Unable to connect to server',
        );

        when(
          mockNetworkClient.get(
            '/api/v5/market/tickers',
            queryParameters: {'instType': 'SPOT'},
            config: NetworkClientConfig.api,
          ),
        ).thenThrow(failure);

        // Act & Assert
        expect(
          () => apiService.getTickers(),
          throwsA(isA<ConnectionFailure>()),
        );
      });
    });
  });
}
