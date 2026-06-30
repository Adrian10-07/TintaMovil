import 'package:get_it/get_it.dart';

import '../network/http_client.dart';

// Auth
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/viewmodels/auth_viewmodel.dart';

// Home
import '../../features/home/data/datasources/book_remote_datasource.dart';
import '../../features/home/data/repositories/book_repository_impl.dart';
import '../../features/home/domain/repositories/book_repository.dart';
import '../../features/home/presentation/viewmodels/home_viewmodel.dart';

// User
import '../../features/user/data/datasources/user_remote_datasource.dart';
import '../../features/user/data/repositories/user_repository_impl.dart';
import '../../features/user/domain/repositories/user_repository.dart';
import '../../features/user/presentation/viewmodels/user_viewmodel.dart';

// Reader
import '../../features/reader/data/datasources/reader_remote_datasource.dart';
import '../../features/reader/data/repositories/reader_repository_impl.dart';
import '../../features/reader/domain/repositories/reader_repository.dart';
import '../../features/reader/presentation/viewmodels/reader_viewmodel.dart';

// Tutor AI
import '../../features/tutorAI/data/datasources/fllama_tutor_datasource.dart';
import '../../features/tutorAI/data/datasources/tutor_llm_datasource.dart';
import '../../features/tutorAI/data/repositories/tutor_repository_impl.dart';
import '../../features/tutorAI/domain/repositories/tutor_repository.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  // ── CORE ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // ── AUTH ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl()),
  );

  sl.registerFactory<AuthViewModel>(
        () => AuthViewModel(sl(), sl()),
  );

  // ── HOME ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<BookRemoteDataSource>(
        () => BookRemoteDataSource(),
  );

  sl.registerLazySingleton<BookRepository>(
        () => BookRepositoryImpl(sl()),
  );

  sl.registerFactory<HomeViewModel>(
        () => HomeViewModel(sl()),
  );

  // ── USER ────────────────────────────────────────────────────────────────
  sl.registerLazySingleton<UserRemoteDataSource>(
        () => UserRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<UserRepository>(
        () => UserRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<UserViewModel>(
        () => UserViewModel(sl()),
  );

  // ── READER ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<ReaderRemoteDataSource>(
        () => ReaderRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<ReaderRepository>(
        () => ReaderRepositoryImpl(sl()),
  );

  sl.registerFactory<ReaderViewModel>(
        () => ReaderViewModel(sl()),
  );

  // ── TUTOR AI ────────────────────────────────────────────────────────────
  registerTutorAi();
}

void registerTutorAi() {
  // Datasource: usa Fllama + Gemma 2 2B GGUF.
  // El modelo se carga una sola vez y se reutiliza.
  sl.registerLazySingleton<TutorLlmDatasource>(
        () => FllamaTutorDatasource(),
  );

  sl.registerLazySingleton<TutorRepository>(
        () => TutorRepositoryImpl(
      sl<TutorLlmDatasource>(),
    ),
  );
}