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

// Tutor AI — TTS (Text-to-Speech)
import '../../features/tutorAI/data/datasources/tts_service.dart';

// Premium / Suscripciones
import '../../features/premium/data/datasources/premium_remote_datasource.dart';
import '../../features/premium/presentation/viewmodels/premium_viewmodel.dart';

// Tutor AI — local (Gemma)
import '../../features/tutorAI/data/datasources/gemma_flutter_tutor_datasource.dart';
import '../../features/tutorAI/data/datasources/tutor_llm_datasource.dart';
import '../../features/tutorAI/data/repositories/tutor_repository_impl.dart';
import '../../features/tutorAI/domain/repositories/tutor_repository.dart';
import '../../features/tutorAI/presentation/viewmodels/tutor_chat_viewmodel.dart';
import '../../features/tutorAI/data/datasources/mock_tutor_datasource.dart';
import '../../features/tutorAI/data/services/model_download_service.dart';
import '../../features/tutorAI/data/services/in_memory_rag_service.dart';

// Tutor AI — remoto (RAG en Railway)
import '/core/network/sse_client.dart';
import '../../features/tutorAI/data/datasources/remote_tutor_datasource.dart';
import '../../features/tutorAI/data/repositories/document_registry_impl.dart';
import '../../features/tutorAI/domain/repositories/document_registry.dart';
import '../../features/tutorAI/presentation/viewmodels/remote_tutor_session_manager.dart';

// Knowledge Base
import '../../features/knowledge_base/data/datasources/knowledge_local_datasource.dart';
import '../../features/knowledge_base/data/repositories/knowledge_repository_impl.dart';
import '../../features/knowledge_base/data/services/pdf_text_extractor.dart';
import '../../features/knowledge_base/data/services/text_chunker.dart';
import '../../features/knowledge_base/data/services/tfidf_engine.dart';
import '../../features/knowledge_base/domain/repositories/knowledge_repository.dart';

// Clubs
import '../../features/clubs/data/datasources/club_remote_datasource.dart';
import '../../features/clubs/data/datasources/club_local_datasource.dart';
import '../../features/clubs/data/repositories/club_repository_impl.dart';
import '../../features/clubs/data/services/moderation_service.dart';
import '../../features/clubs/data/services/websocket_service.dart';
import '../../features/clubs/data/services/club_notification_service.dart';
import '../../features/clubs/data/services/user_cache_service.dart';
import '../../features/clubs/domain/repositories/club_repository.dart';
import '../../features/clubs/presentation/viewmodels/clubs_viewmodel.dart';

final sl = GetIt.instance;

const String _tutorAiBaseUrl =
    'https://tutor-ai-production-c85c.up.railway.app';

// FLAG DE DESARROLLO: Cambiar a `true` para usar el MockTutorDatasource
// en vez del modelo real (útil en emulador x86_64, donde flutter_gemma
// no tiene binarios nativos compatibles).
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

  // ── PREMIUM / SUSCRIPCIONES ──────────────────────────────────────────
  registerPremium();

  // ── CLUBS ─────────────────────────────────────────────────────────────
  registerClubs();

  // ── KNOWLEDGE BASE ──────────────────────────────────────────────────────
  registerKnowledgeBase();

  // ── TUTOR AI ────────────────────────────────────────────────────────────
  registerTutorAi();
}

void registerPremium() {
  sl.registerLazySingleton<PremiumRemoteDatasource>(
        () => PremiumRemoteDatasource(sl()),
  );

  sl.registerLazySingleton<PremiumViewModel>(
        () => PremiumViewModel(sl()),
  );
}

void registerClubs() {
  sl.registerLazySingleton<ClubRemoteDataSource>(
        () => ClubRemoteDataSource(sl()),
  );

  sl.registerLazySingleton<ClubLocalDataSource>(
        () => ClubLocalDataSource(),
  );

  sl.registerLazySingleton<ModerationService>(
        () => ModerationService(),
  );

  sl.registerLazySingleton<WebSocketService>(
        () => WebSocketService(),
  );

  sl.registerLazySingleton<UserCacheService>(
        () => UserCacheService(sl()),
  );

  sl.registerLazySingleton<ClubRepository>(
        () => ClubRepositoryImpl(
      remote: sl(),
      local: sl(),
    ),
  );

  sl.registerLazySingleton<ClubNotificationService>(
        () => ClubNotificationService(sl()),
  );

  sl.registerLazySingleton<ClubsViewModel>(
        () => ClubsViewModel(sl(), sl()),
  );
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
  // ── TTS (Text-to-Speech) ─────────────────────────────────────
  // Singleton compartido entre el chat local y el remoto.
  sl.registerLazySingleton<TtsService>(() => TtsService());

  // Datasource activo del tutor local: Gemma 3 1B vía flutter_gemma.
  sl.registerLazySingleton<TutorLlmDatasource>(
        () => _useMockLlmForEmulator
        ? MockTutorDatasource()
        : GemmaFlutterTutorDatasource(
      huggingFaceToken: _huggingFaceToken,
    ),
  );

  // Servicio de descarga (bridge al datasource para la UI).
  sl.registerLazySingleton<ModelDownloadService>(
        () => ModelDownloadService(sl<TutorLlmDatasource>()),
  );

  sl.registerLazySingleton<TutorRepository>(
        () => TutorRepositoryImpl(
      sl<TutorLlmDatasource>(),
    ),
  );

  sl.registerLazySingleton<InMemoryRagService>(
        () => InMemoryRagService(),
  );

  sl.registerLazySingleton<TutorChatViewModel>(
        () => TutorChatViewModel(
      sl<TutorRepository>(),
      sl<InMemoryRagService>(),
    ),
  );

  // ── Modo remoto (RAG en Railway) ─────────────────────────────────
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

  sl.registerLazySingleton<RemoteTutorSessionManager>(
        () => RemoteTutorSessionManager(sl<RemoteTutorDatasource>()),
  );
}