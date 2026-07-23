import 'dart:async';

import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide Message;
import 'package:flutter_gemma/flutter_gemma.dart' as gemma show Message;

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import 'tutor_llm_datasource.dart';

/// Datasource que ejecuta Gemma 3 1B on-device usando `flutter_gemma`
/// (MediaPipe / LiteRT-LM).
class GemmaFlutterTutorDatasource implements TutorLlmDatasource {
  // URL del modelo Gemma 3 1B en formato .task (MediaPipe), ~530 MB.
  // Ver https://huggingface.co/litert-community/Gemma3-1B-IT
  static const String _modelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task';
  static const String _modelName = 'gemma3-1b-it-int4.task';

  /// Token de HuggingFace para descargar modelos "gated". Se inyecta desde
  /// afuera (ver README de integración) usando --dart-define-from-file para
  /// no comprometer el secreto en el repositorio.
  final String huggingFaceToken;

  static const int _maxTokens = 512;

  final StreamController<ModelDownloadStatus> _statusController =
  StreamController<ModelDownloadStatus>.broadcast();

  InferenceModel? _model;
  InferenceChat? _chat;
  bool _isReady = false;
  bool _isInitializing = false;

  GemmaFlutterTutorDatasource({required this.huggingFaceToken});

  @override
  Stream<ModelDownloadStatus> get statusStream => _statusController.stream;

  @override
  Future<void> ensureModelReady() async {
    if (_isReady) return;
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      _statusController.add(
        const ModelDownloadStatus(stage: ModelDownloadStage.checking),
      );

      final alreadyInstalled =
      await FlutterGemma.isModelInstalled(_modelName);

      if (!alreadyInstalled) {
        _statusController.add(
          const ModelDownloadStatus(stage: ModelDownloadStage.downloading),
        );

        // Descarga automática desde HuggingFace. El paquete reintenta solo
        // (maxDownloadRetries configurado en FlutterGemma.initialize() en
        // main.dart) y usa foreground service en Android para archivos
        // >500MB, evitando el límite de 9 min en background.
        await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
            .fromNetwork(_modelUrl, token: huggingFaceToken)
            .withProgress((progress) {
          _statusController.add(
            ModelDownloadStatus(
              stage: ModelDownloadStage.downloading,
              bytesDownloaded: progress,
              totalBytes: 100,
            ),
          );
        }).install();
      }

      _statusController.add(
        const ModelDownloadStatus(stage: ModelDownloadStage.loading),
      );

      // CPU por defecto: más compatible en gama baja que forzar GPU.
      _model = await FlutterGemma.getActiveModel(
        maxTokens: _maxTokens,
        preferredBackend: PreferredBackend.cpu,
      );

      _isReady = true;
      _statusController.add(
        const ModelDownloadStatus(stage: ModelDownloadStage.ready),
      );
    } catch (e) {
      _statusController.add(
        ModelDownloadStatus(
          stage: ModelDownloadStage.failed,
          errorMessage: e.toString(),
        ),
      );
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  @override
  Stream<String> generate({
    required String systemPrompt,
    required List<ChatMessage> history,
  }) async* {
    if (!_isReady || _model == null) {
      throw StateError('Modelo no listo.');
    }

    // Sesión NUEVA en cada turno. No reutilizamos la sesión anterior:
    // en pruebas se observó un crash nativo (SIGSEGV en CopyCache /
    // CloneContext dentro de libllm_inference_engine_jni.so) al reutilizar
    // contexto tras un turno anterior. Cerrar y recrear es más lento
    // (se reprocesa el historial acotado) pero mucho más estable.
    await _chat?.session.close();
    _chat = await _model!.createChat(systemInstruction: systemPrompt);

    final pastMessages = history.where((m) => !m.isSystem && !m.isStreaming);
    for (final m in pastMessages) {
      await _chat!.addQueryChunk(
        gemma.Message.text(text: m.content, isUser: m.isUser),
      );
    }

    // ── Guardia anti-repetición ─────────────────────────────────────
    // Gemma 3 1B cuantizado puede degenerar en loops (mismo token
    // repetido) en generaciones largas. Cortamos dejando de escuchar el
    // stream (`break`) en vez de llamar a stopGeneration(): esa llamada
    // nativa parece dejar el KV-cache en estado inconsistente y provocó
    // un crash SIGSEGV en el siguiente turno durante pruebas.
    String? lastToken;
    int repeatCount = 0;
    const maxRepeats = 15;

    await for (final response in _chat!.generateChatResponseAsync()) {
      if (response is TextResponse) {
        if (response.token == lastToken) {
          repeatCount++;
          if (repeatCount >= maxRepeats) {
            break;
          }
        } else {
          repeatCount = 0;
          lastToken = response.token;
        }
        yield response.token;
      }
    }
  }

  @override
  Future<void> deleteModel() async {
    await _chat?.session.close();
    _chat = null;
    await _model?.close();
    _model = null;
    _isReady = false;
    _statusController.add(
      const ModelDownloadStatus(stage: ModelDownloadStage.idle),
    );
  }

  @override
  Future<void> dispose() async {
    await _chat?.session.close();
    _chat = null;
    await _model?.close();
    _model = null;
    await _statusController.close();
  }
}
