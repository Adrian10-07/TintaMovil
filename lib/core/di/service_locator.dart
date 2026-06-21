import 'package:get_it/get_it.dart';

import '../network/http_client.dart';

// Importaciones de Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';

// Importaciones de Home
import '../../features/home/data/datasources/book_remote_datasource.dart';
import '../../features/home/data/repositories/book_repository_impl.dart';
import '../../features/home/domain/repositories/book_repository.dart';
import '../../features/home/presentation/viewmodels/home_viewmodel.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // --- CORE ---
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // --- FEATURE: AUTH ---
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSource(), // Aquí inyectarías el ApiClient cuando tengas tu API real
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl()),
  );

  // ViewModels (Factory porque queremos uno nuevo si la vista se destruye y vuelve a crear)
  sl.registerFactory<AuthViewModel>(
        () => AuthViewModel(sl()),
  );

  // --- FEATURE: HOME ---
  // Data sources
  sl.registerLazySingleton<BookRemoteDataSource>(
        () => BookRemoteDataSource(sl()), // Inyectamos el ApiClient real
  );

  // Repositories
  sl.registerLazySingleton<BookRepository>(
        () => BookRepositoryImpl(sl()),
  );

  // ViewModels
  sl.registerFactory<HomeViewModel>(
        () => HomeViewModel(sl()),
  );
}