import 'dart:async';

import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide Message;
import 'package:flutter_gemma/flutter_gemma.dart' as gemma show Message;

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import 'tutor_llm_datasource.dart';

/// Datasource que ejecuta Gemma 3 1B on-device usando `flutter_gemma`.
class GemmaFlutterTutorDatasource implements TutorLlmDatasource {
  static const String _modelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task';
  static const String _modelName = 'gemma3-1b-it-int4.task';
  static const int _knownTotalBytes = 554661243;

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

  ModelDownloadStatus _lastStatus =
  const ModelDownloadStatus(stage: ModelDownloadStage.idle);
  ModelDownloadStatus get lastStatus => _lastStatus;

  void _emit(ModelDownloadStatus status) {
    _lastStatus = status;
    _statusController.add(status);
  }

  @override
  Future<void> ensureModelReady() async {
    // ── FIX de condición de carrera con el precargado en background ──
    // Si el modelo ya quedó listo (por ejemplo, precargado desde
    // main.dart mucho antes de que el usuario abriera el chat), el
    // evento "ready" del stream broadcast ya se emitió y se perdió
    // para cualquier oyente que se suscriba después (los streams
    // broadcast no repiten eventos pasados). Sin este re-emit, el
    // ViewModel del chat se queda esperando un evento que nunca va a
    // llegar, mostrando para siempre el último estado que sí alcanzó
    // a ver (por ejemplo "checking"), aunque el modelo esté 100% listo.
    if (_isReady) {
      _emit(const ModelDownloadStatus(stage: ModelDownloadStage.ready));
      return;
    }

    if (_isInitializing) {
      // Ya hay una inicialización en curso desde otro llamador (el
      // precargado en background). Reemitimos el último estado
      // conocido para que este nuevo oyente vea de inmediato en qué
      // va el proceso, en vez de quedarse en blanco/idle. Los eventos
      // SIGUIENTES de esta misma inicialización sí le llegarán con
      // normalidad, porque la suscripción ya está activa.
      _emit(_lastStatus);
      return;
    }

    _isInitializing = true;

    try {
      // ── RED DE SEGURIDAD FINAL ────────────────────────────────────
      // Sin importar en qué paso interno se cuelgue (isModelInstalled,
      // install, getActiveModel, o cualquier llamada nativa que no
      // respete sus propios timeouts), este límite de 45s garantiza
      // que el usuario SIEMPRE vea un estado final (ready o failed),
      // nunca un spinner infinito.
      await _ensureModelReadyInner().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          throw TimeoutException(
            'El tutor tardó demasiado en prepararse. '
                'Verifica tu conexión o intenta de nuevo.',
          );
        },
      );
    } catch (e) {
      _emit(ModelDownloadStatus(
        stage: ModelDownloadStage.failed,
        errorMessage: e.toString(),
      ));
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _ensureModelReadyInner() async {
    _emit(const ModelDownloadStatus(stage: ModelDownloadStage.checking));

    final alreadyInstalled = await FlutterGemma.isModelInstalled(_modelName)
        .timeout(
      const Duration(seconds: 5),
      onTimeout: () => true,
    );

    if (!alreadyInstalled) {
      _emit(const ModelDownloadStatus(stage: ModelDownloadStage.downloading));

      await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
          .fromNetwork(_modelUrl, token: huggingFaceToken)
          .withProgress((percent) {
        final bytesDownloaded = ((percent / 100) * _knownTotalBytes).round();
        _emit(ModelDownloadStatus(
          stage: ModelDownloadStage.downloading,
          bytesDownloaded: bytesDownloaded,
          totalBytes: _knownTotalBytes,
        ));
      }).install();
    }

    _emit(const ModelDownloadStatus(stage: ModelDownloadStage.loading));

    _model = await FlutterGemma.getActiveModel(
      maxTokens: _maxTokens,
      preferredBackend: PreferredBackend.cpu,
    );

    _isReady = true;
    _emit(const ModelDownloadStatus(stage: ModelDownloadStage.ready));
  }

  @override
  Stream<String> generate({
    required String systemPrompt,
    required List<ChatMessage> history,
  }) async* {
    if (!_isReady || _model == null) {
      throw StateError('Modelo no listo.');
    }

    await _chat?.session.close();
    _chat = await _model!.createChat(systemInstruction: systemPrompt);

    final pastMessages = history.where((m) => !m.isSystem && !m.isStreaming);
    for (final m in pastMessages) {
      await _chat!.addQueryChunk(
        gemma.Message.text(text: m.content, isUser: m.isUser),
      );
    }

    String? lastToken;
    int repeatCount = 0;
    const maxRepeats = 15;

    await for (final response in _chat!.generateChatResponseAsync()) {
      if (response is TextResponse) {
        if (response.token == lastToken) {
          repeatCount++;
          if (repeatCount >= maxRepeats) break;
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
    _emit(const ModelDownloadStatus(stage: ModelDownloadStage.idle));
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