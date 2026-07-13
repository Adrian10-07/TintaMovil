import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import '../../domain/repositories/tutor_repository.dart';
import '../datasources/tutor_llm_datasource.dart';

class TutorRepositoryImpl implements TutorRepository {
  final TutorLlmDatasource _datasource;

  TutorRepositoryImpl(this._datasource);

  @override
  Stream<ModelDownloadStatus> get downloadStatus => _datasource.statusStream;

  @override
  Future<void> ensureModelReady() => _datasource.ensureModelReady();

  @override
  Stream<String> generateResponse({
    required List<ChatMessage> history,
    String? documentContext,
    List<String>? relevantChunks,
  }) {
    String systemPrompt;

    if (relevantChunks != null && relevantChunks.isNotEmpty) {
      // RAG mode: inyectar fragmentos relevantes del documento.
      // Truncar cada chunk a ~200 chars para caber en 1024 tokens de contexto.
      final truncatedChunks = relevantChunks
          .take(2) // máximo 2 fragmentos con contexto reducido
          .map((c) => c.length > 200 ? '${c.substring(0, 200)}...' : c)
          .toList();
      final chunksText = truncatedChunks
          .asMap()
          .entries
          .map((e) => '[Fragmento ${e.key + 1}]: ${e.value}')
          .join('\n\n');

      systemPrompt =
      'Eres Tinta AI, un tutor amigable que ayuda al estudiante con la lectura. '
          'El usuario está leyendo un documento. '
          'A continuación tienes los fragmentos más relevantes del documento para responder su pregunta:\n\n'
          '$chunksText\n\n'
          'Responde SOLO basándote en estos fragmentos. '
          'Si la información no está en los fragmentos, dilo honestamente. '
          'Sé educativo y motivador.';
    } else if (documentContext != null) {
      // Fallback: solo el nombre del documento sin RAG.
      String? truncatedContext = documentContext;
      if (truncatedContext.length > 1000) {
        truncatedContext = '${truncatedContext.substring(0, 1000)}...';
      }
      systemPrompt =
      'Eres Tinta AI, un tutor amigable que ayuda al estudiante con la lectura. '
          'El usuario está leyendo un documento (fragmento inicial): "$truncatedContext". '
          'Responde preguntas sobre el contenido de forma educativa y motivadora.';
    } else {
      // Modo general sin documento.
      systemPrompt = 'Eres Tinta AI, un tutor amigable. '
          'Ayudas al estudiante con sus dudas de forma educativa y motivadora.';
    }

    return _datasource.generate(
      systemPrompt: systemPrompt,
      history: history,
    );
  }

  @override
  Future<void> dispose() => _datasource.dispose();
}