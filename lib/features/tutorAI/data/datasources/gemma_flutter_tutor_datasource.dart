import 'dart:async';

import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_gemma/flutter_gemma.dart' hide Message;
import 'package:flutter_gemma/flutter_gemma.dart' as gemma show Message;

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import 'tutor_llm_datasource.dart';

/// Datasource que ejecuta Gemma 3 1B on-device usando `flutter_gemma`.

/// La descarga se dispara UNA vez, en background, apenas arranca la app
/// para que la UI pueda mostrar "265 MB / 529 MB" tanto en el Home como
class GemmaFlutterTutorDatasource implements TutorLlmDatasource {
  static const String _modelUrl =
      'https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/gemma3-1b-it-int4.task';
  static const String _modelName = 'gemma3-1b-it-int4.task';

  /// Tamaño real del archivo .task, confirmado por descarga previa
  /// (554,661,243 bytes ≈ 529 MB). Se usa como referencia fija para
  /// calcular bytes descargados a partir del porcentaje que reporta
  /// flutter_gemma, ya que la librería solo expone 0-100%, no bytes.
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

  /// Estado actual, para que un widget que se monta DESPUÉS de que la
  /// descarga ya empezó (por ejemplo el chat, si el usuario lo abre a
  /// mitad de la descarga en background) pueda pintar el estado correcto
  /// de inmediato en vez de esperar el próximo evento del stream.
  ModelDownloadStatus _lastStatus =
  const ModelDownloadStatus(stage: ModelDownloadStage.idle);
  ModelDownloadStatus get lastStatus => _lastStatus;

  void _emit(ModelDownloadStatus status) {
    _lastStatus = status;
    _statusController.add(status);
  }

  @override
  Future<void> ensureModelReady() async {
    if (_isReady) return;
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      _emit(const ModelDownloadStatus(stage: ModelDownloadStage.checking));

      final alreadyInstalled = await FlutterGemma.isModelInstalled(_modelName);

      if (!alreadyInstalled) {
        _emit(const ModelDownloadStatus(stage: ModelDownloadStage.downloading));

        await FlutterGemma.installModel(modelType: ModelType.gemmaIt)
            .fromNetwork(_modelUrl, token: huggingFaceToken)
            .withProgress((percent) {
          // flutter_gemma solo reporta 0-100. Lo convertimos a bytes
          // reales usando el tamaño conocido del archivo, para que la
          // UI pueda mostrar "265 MB / 529 MB" en vez de solo "50%".
          final bytesDownloaded =
          ((percent / 100) * _knownTotalBytes).round();
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
