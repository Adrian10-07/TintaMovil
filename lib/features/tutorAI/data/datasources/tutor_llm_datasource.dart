import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';

/// Interfaz abstracta del datasource del LLM.
abstract class TutorLlmDatasource {
  Stream<ModelDownloadStatus> get statusStream;
  ModelDownloadStatus get lastStatus;

  Future<void> ensureModelReady();
  Stream<String> generate({
    required String systemPrompt,
    required List<ChatMessage> history,
  });
  Future<void> deleteModel();
  Future<void> dispose();
}
