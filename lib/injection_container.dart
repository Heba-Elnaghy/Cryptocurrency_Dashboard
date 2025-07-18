import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';

// Core
import 'core/network/network.dart';
import 'core/error/error_handling.dart';

// Data
import 'data/datasources/okx_api_service.dart';
import 'data/repositories/cryptocurrency_repository_impl.dart';

// Domain
import 'domain/repositories/cryptocurrency_repository.dart';
import 'domain/usecases/get_initial_cryptocurrencies.dart';
import 'domain/usecases/subscribe_to_real_time_updates.dart';
import 'domain/usecases/manage_connection_lifecycle.dart';

// Presentation
import 'presentation/bloc/cryptocurrency_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  sl.registerLazySingleton(() => Dio());

  // Core - Network
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<OfflineManager>(() => OfflineManager(sl()));
  sl.registerLazySingleton<OfflineDetector>(() => OfflineDetector());
  sl.registerLazySingleton<NetworkErrorHandler>(
    () =>
        NetworkErrorHandler(sl(), offlineManager: sl(), offlineDetector: sl()),
  );

  // Core - Error handling
  sl.registerLazySingleton<ErrorRecoveryService>(
    () => ErrorRecoveryService(sl()),
  );

  // Data sources
  sl.registerLazySingleton<OKXApiService>(
    () => OKXApiService(
      networkInfo: sl(),
      offlineManager: sl(),
      offlineDetector: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<CryptocurrencyRepository>(
    () => CryptocurrencyRepositoryImpl(sl(), sl(), sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetInitialCryptocurrencies(sl()));
  sl.registerLazySingleton(() => SubscribeToRealTimeUpdates(sl()));
  sl.registerLazySingleton(() => ManageConnectionLifecycle(sl()));

  // BLoC
  sl.registerFactory(
    () => CryptocurrencyBloc(
      getInitialCryptocurrencies: sl(),
      subscribeToRealTimeUpdates: sl(),
      manageConnectionLifecycle: sl(),
    ),
  );
}
