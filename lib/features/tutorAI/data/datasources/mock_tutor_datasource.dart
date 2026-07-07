import 'dart:async';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import 'tutor_llm_datasource.dart';

/// Datasource simulado para usar en emuladores x86_64 donde fllama crashea.
///
/// Simula la descarga y generación de respuestas, permitiendo probar
/// el flujo RAG y la interfaz de usuario sin requerir un dispositivo físico.
class MockTutorDatasource implements TutorLlmDatasource {
  final StreamController<ModelDownloadStatus> _statusController =
      StreamController<ModelDownloadStatus>.broadcast();

  bool _isReady = false;

  @override
  Stream<ModelDownloadStatus> get statusStream => _statusController.stream;

  @override
  Future<void> ensureModelReady() async {
    if (_isReady) return;

    _statusController.add(
      const ModelDownloadStatus(stage: ModelDownloadStage.checking),
    );
    await Future.delayed(const Duration(milliseconds: 500));

    _statusController.add(
      const ModelDownloadStatus(
        stage: ModelDownloadStage.downloading,
        bytesDownloaded: 500000000,
        totalBytes: 1500000000,
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));

    _statusController.add(
      const ModelDownloadStatus(stage: ModelDownloadStage.loading),
    );
    await Future.delayed(const Duration(milliseconds: 500));

    _isReady = true;
    _statusController.add(
      const ModelDownloadStatus(stage: ModelDownloadStage.ready),
    );
  }

  @override
  Stream<String> generate({
    required String systemPrompt,
    required List<ChatMessage> history,
  }) async* {
    if (!_isReady) throw StateError('Modelo no listo');

    final lastMessage = history.lastWhere((m) => m.isUser).content;
    
    // Extraer los chunks del systemPrompt para demostrar que RAG funciona
    final ragMatches = RegExp(r'\[Fragmento \d+\]: (.*?)(?=\[Fragmento|$)', dotAll: true)
        .allMatches(systemPrompt);
        
    String responseText;
    
    if (ragMatches.isNotEmpty) {
      responseText = '¡Hola! Simulando respuesta con RAG activado.\n\n'
          'Me preguntaste: "$lastMessage"\n\n'
          'He recibido ${ragMatches.length} fragmentos de contexto de tu PDF. '
          'Por ejemplo, el primer fragmento dice:\n\n'
          '> "${ragMatches.first.group(1)?.trim().substring(0, 50)}..."\n\n'
          '¡El sistema RAG está funcionando perfectamente offline!';
    } else {
      responseText = '¡Hola! Soy el tutor simulado. \n'
          'Me dijiste: "$lastMessage"\n\n'
          '(Nota: RAG no está activo o no se encontraron fragmentos relevantes)';
    }

    // Simular streaming palabra por palabra
    final words = responseText.split(' ');
    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 50));
      yield '$word ';
    }
  }

  @override
  Future<void> deleteModel() async {
    _isReady = false;
    _statusController.add(
      const ModelDownloadStatus(stage: ModelDownloadStage.idle),
    );
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
  }
}
