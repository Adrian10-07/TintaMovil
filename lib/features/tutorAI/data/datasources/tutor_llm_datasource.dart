import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';

/// Interfaz abstracta del datasource del LLM.
///
/// La implementación concreta (`FllamaTutorDatasource`) usa fllama para
/// ejecutar Gemma 2 2B GGUF en el dispositivo. En el futuro podríamos
/// tener un `MockTutorDatasource` para tests o un `RemoteTutorDatasource`
/// que llame a una API externa.
abstract class TutorLlmDatasource {
  Stream<ModelDownloadStatus> get statusStream;

  Future<void> ensureModelReady();

  /// Genera respuesta. El [systemPrompt] ya viene armado por el repositorio
  /// (incluye personalidad + contexto del documento si lo hay).
  Stream<String> generate({
    required String systemPrompt,
    required List<ChatMessage> history,
  });

  Future<void> dispose();
}
