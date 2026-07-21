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
import '../../features/tutorAI/data/datasources/gemma_flutter_tutor_datasource.dart';
import '../../features/tutorAI/data/datasources/tutor_llm_datasource.dart';
import '../../features/tutorAI/data/repositories/tutor_repository_impl.dart';
import '../../features/tutorAI/domain/repositories/tutor_repository.dart';
import '../../features/tutorAI/presentation/viewmodels/tutor_chat_viewmodel.dart';

import '/core/network/sse_client.dart';
import '../../features/tutorAI/data/datasources/remote_tutor_datasource.dart';
import '../../features/tutorAI/data/repositories/document_registry_impl.dart';
import '../../features/tutorAI/domain/repositories/document_registry.dart';

// Knowledge Base
import '../../features/knowledge_base/data/datasources/knowledge_local_datasource.dart';
import '../../features/knowledge_base/data/repositories/knowledge_repository_impl.dart';
import '../../features/knowledge_base/data/services/pdf_text_extractor.dart';
import '../../features/knowledge_base/data/services/text_chunker.dart';
import '../../features/knowledge_base/data/services/tfidf_engine.dart';
import '../../features/knowledge_base/domain/repositories/knowledge_repository.dart';

import '../../features/tutorAI/data/datasources/mock_tutor_datasource.dart';

final sl = GetIt.instance;

const String _tutorAiBaseUrl = 'https://tutor-ai-production-c85c.up.railway.app';


// FLAG DE DESARROLLO: Cambiar a `false` para usar el modelo real en un
// teléfono físico ARM64. En emuladores x86_64 fllama puede no funcionar.
const bool _useMockLlmForEmulator = false;
const String _huggingFaceToken = String.fromEnvironment('HUGGINGFACE_TOKEN');

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

  // ── KNOWLEDGE BASE ──────────────────────────────────────────────────────
  registerKnowledgeBase();

  // ── TUTOR AI ────────────────────────────────────────────────────────────
  registerTutorAi();
}

void registerKnowledgeBase() {
  sl.registerLazySingleton<PdfTextExtractor>(() => PdfTextExtractor());
  sl.registerLazySingleton<TextChunker>(() => TextChunker());
  sl.registerLazySingleton<TfidfEngine>(() => TfidfEngine());
  
  sl.registerLazySingleton<KnowledgeLocalDatasource>(
    () => KnowledgeLocalDatasource(),
  );

  sl.registerLazySingleton<KnowledgeRepository>(
    () => KnowledgeRepositoryImpl(
      pdfExtractor: sl(),
      chunker: sl(),
      tfidfEngine: sl(),
      datasource: sl(),
    ),
  );
}

void registerTutorAi() {
  // Los datasources originales de tu compañero se mantienen registrados
  // por si activan el modo offline después. NO se están usando activamente.
  sl.registerLazySingleton<TutorLlmDatasource>(
        () => _useMockLlmForEmulator
        ? MockTutorDatasource()
        : GemmaFlutterTutorDatasource(
            huggingFaceToken: _huggingFaceToken,
        ),
  );

  sl.registerLazySingleton<TutorRepository>(
        () => TutorRepositoryImpl(sl<TutorLlmDatasource>()),
  );

  sl.registerLazySingleton<TutorChatViewModel>(
        () => TutorChatViewModel(
      sl<TutorRepository>(),
      sl<KnowledgeRepository>(),
    ),
  );

  // ── NUEVO: modo remoto ──────────────────────────────────────────
  sl.registerLazySingleton<SseClient>(() => SseClient());

  sl.registerLazySingleton<RemoteTutorDatasource>(
        () => RemoteTutorDatasource(
      baseUrl: _tutorAiBaseUrl,
      apiClient: sl<ApiClient>(),
      sseClient: sl<SseClient>(),
    ),
  );

  sl.registerLazySingleton<DocumentRegistry>(
        () => DocumentRegistryImpl(),
  );
}
