import 'dart:async';
import 'dart:io';

import 'package:fllama/fllama.dart';
import 'package:fllama/fllama_type.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import 'tutor_llm_datasource.dart';

class FllamaTutorDatasource implements TutorLlmDatasource {
  static const String _modelUrl =
      'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf';
  static const String _modelFileName = 'gemma-2-2b-it-q4_k_m.gguf';

  static const int _contextSize = 2048;
  static const int _maxTokens = 512;
  static const double _temperature = 0.7;
  static const double _topP = 0.9;

  final StreamController<ModelDownloadStatus> _statusController =
      StreamController<ModelDownloadStatus>.broadcast();

  double? _contextId;
  bool _isReady = false;
  bool _isInitializing = false;
  StreamSubscription<Map<Object?, dynamic>>? _tokenSubscription;

  @override
  Stream<ModelDownloadStatus> get statusStream => _statusController.stream;

  Future<String> _resolveModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_modelFileName';
  }

  @override
  Future<void> ensureModelReady() async {
    if (_isReady) return;
    if (_isInitializing) return;
    _isInitializing = true;

    try {
      _statusController.add(
        const ModelDownloadStatus(stage: ModelDownloadStage.checking),
      );

      final path = await _resolveModelPath();
      final file = File(path);

      if (!await file.exists()) {
        await _downloadModel(path);
      } else {
        final size = await file.length();
        if (size < 500 * 1024 * 1024) {
          await file.delete();
          await _downloadModel(path);
        }
      }

      _statusController.add(
        const ModelDownloadStatus(stage: ModelDownloadStage.loading),
      );

      final result = await Fllama.instance()!.initContext(
        path,
        nCtx: _contextSize,
        nGpuLayers: 0,
      );

      if (result == null || !result.containsKey('id')) {
        throw Exception('Failed to initialize model context');
      }

      _contextId = (result['id'] as num).toDouble();
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

  Future<void> _downloadModel(String savePath) async {
    final partialPath = '$savePath.partial';
    final partialFile = File(partialPath);

    if (await partialFile.exists()) {
      await partialFile.delete();
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(_modelUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'Error al descargar modelo: HTTP ${response.statusCode}',
        );
      }

      final totalBytes = response.contentLength ?? 0;
      int bytesDownloaded = 0;

      final sink = partialFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        bytesDownloaded += chunk.length;

        _statusController.add(
          ModelDownloadStatus(
            stage: ModelDownloadStage.downloading,
            bytesDownloaded: bytesDownloaded,
            totalBytes: totalBytes,
          ),
        );
      }

      await sink.flush();
      await sink.close();

      await partialFile.rename(savePath);
    } finally {
      client.close();
    }
  }

  @override
  Stream<String> generate({
    required String systemPrompt,
    required List<ChatMessage> history,
  }) async* {
    if (!_isReady || _contextId == null) {
      throw StateError(
        'El modelo no está listo. Llama ensureModelReady() primero.',
      );
    }

    final fllama = Fllama.instance()!;
    final messages = <RoleContent>[
      RoleContent(role: 'system', content: systemPrompt),
      for (final m in history.where((m) => !m.isSystem))
        RoleContent(
          role: m.isUser ? 'user' : 'assistant',
          content: m.content,
        ),
    ];

    final prompt = await fllama.getFormattedChat(
      _contextId!,
      messages: messages,
    );

    if (prompt == null || prompt.isEmpty) {
      throw Exception('Failed to format chat prompt');
    }

    final controller = StreamController<String>();
    StreamSubscription<Map<Object?, dynamic>>? sub;

    sub = fllama.onTokenStream?.listen(
      (event) {
        final eventCtx = (event['contextId'] as num?)?.toDouble();
        if (eventCtx != _contextId) return;

        if (event['done'] == true) {
          sub?.cancel();
          controller.close();
        } else {
          final token = event['token'] as String? ??
              event['text'] as String?;
          if (token != null && token.isNotEmpty) {
            controller.add(token);
          }
        }
      },
      onError: (error) {
        sub?.cancel();
        controller.addError(error);
      },
      onDone: () {
        if (!controller.isClosed) controller.close();
      },
    );

    await fllama.completion(
      _contextId!,
      prompt: prompt,
      temperature: _temperature,
      topP: _topP,
      nPredict: _maxTokens,
      emitRealtimeCompletion: true,
    );

    yield* controller.stream;
  }

  @override
  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    if (_contextId != null) {
      Fllama.instance()?.releaseContext(_contextId!);
    }
    await _statusController.close();
  }
}
