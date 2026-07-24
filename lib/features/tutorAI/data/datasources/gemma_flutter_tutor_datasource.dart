import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide Message;
import 'package:flutter_gemma/flutter_gemma.dart' as gemma show Message;

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import 'tutor_llm_datasource.dart';

/// Datasource que ejecuta Gemma 3 1B on-device usando `flutter_gemma`.
///
/// Fixes aplicados:
/// - Sin timeout artificial de 45s — la descarga toma el tiempo que necesite.
/// - Offline: si el modelo ya está instalado, carga sin internet.
/// - No re-descarga si ya está instalado — verifica primero.
/// - Si la carga falla, reintenta una vez antes de reportar error.
class GemmaFlutterTutorDatasource implements TutorLlmDatasource {
  static const String _modelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task';
  static const String _modelName = 'gemma3-1b-it-int4.task';
  static const int _knownTotalBytes = 554661243;
  static const int _maxTokens = 512;

  final String huggingFaceToken;

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

  @override
  ModelDownloadStatus get lastStatus => _lastStatus;

  void _emit(ModelDownloadStatus status) {
    _lastStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  @override
  Future<void> ensureModelReady() async {
    // Ya listo → re-emitir y salir.
    if (_isReady) {
      _emit(const ModelDownloadStatus(stage: ModelDownloadStage.ready));
      return;
    }

    // Otra inicialización en curso → re-emitir último estado.
    if (_isInitializing) {
      _emit(_lastStatus);
      return;
    }

    _isInitializing = true;

    try {
      await _ensureModelReadyInner();
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

    // 1. Verificar si ya está instalado (timeout corto — es una operación local).
    bool alreadyInstalled = false;
    try {
      alreadyInstalled = await FlutterGemma.isModelInstalled(_modelName)
          .timeout(const Duration(seconds: 5), onTimeout: () => false);
    } catch (e) {
      debugPrint('isModelInstalled check failed: $e');
      // Asumir que no está instalado y continuar.
    }

    // 2. Si no está instalado, descargarlo.
    if (!alreadyInstalled) {
      _emit(const ModelDownloadStatus(stage: ModelDownloadStage.downloading));

      try {
        await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
            .fromNetwork(_modelUrl, token: huggingFaceToken)
            .withProgress((percent) {
          final bytesDownloaded =
          ((percent / 100) * _knownTotalBytes).round();
          _emit(ModelDownloadStatus(
            stage: ModelDownloadStage.downloading,
            bytesDownloaded: bytesDownloaded,
            totalBytes: _knownTotalBytes,
          ));
        }).install();
      } catch (e) {
        // Si falla la descarga (sin internet), reportar y salir.
        _emit(ModelDownloadStatus(
          stage: ModelDownloadStage.failed,
          errorMessage: 'No se pudo descargar el modelo. '
              'Verifica tu conexión a internet e intenta de nuevo.',
        ));
        return;
      }
    }

    // 3. Cargar el modelo en memoria.
    _emit(const ModelDownloadStatus(stage: ModelDownloadStage.loading));

    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: _maxTokens,
        preferredBackend: PreferredBackend.cpu,
      );
    } catch (e) {
      // Reintentar una vez — a veces la primera carga falla.
      debugPrint('First load attempt failed: $e — retrying...');
      await Future.delayed(const Duration(seconds: 2));
      try {
        _model = await FlutterGemma.getActiveModel(
          maxTokens: _maxTokens,
          preferredBackend: PreferredBackend.cpu,
        );
      } catch (e2) {
        _emit(ModelDownloadStatus(
          stage: ModelDownloadStage.failed,
          errorMessage: 'No se pudo cargar el modelo: $e2',
        ));
        return;
      }
    }

    _isReady = true;
    _emit(const ModelDownloadStatus(stage: ModelDownloadStage.ready));
  }

  // ── Generación ─────────────────────────────────────────────────────────

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

    final pastMessages =
    history.where((m) => !m.isSystem && !m.isStreaming);
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