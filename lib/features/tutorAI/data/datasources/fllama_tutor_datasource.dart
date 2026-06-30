import 'dart:async';
import 'dart:io';

import 'package:fllama/fllama.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import 'tutor_llm_datasource.dart';

class FllamaTutorDatasource implements TutorLlmDatasource {
  static const String _modelUrl =
      'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf';
  static const String _modelFileName = 'gemma-2-2b-it-q4_k_m.gguf';

  static const int _contextSize = 1024;
  static const int _maxTokens = 384;
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

      Map<Object?, dynamic>? result;
      int gpuLayersUsed = 0;

// Intento 1: con GPU (99 = todas las capas en GPU).
      try {
        print('[Tutor] Intentando cargar con GPU...');
        result = await Fllama.instance()!.initContext(
          path,
          nCtx: _contextSize,
          nGpuLayers: 99,
        );
        gpuLayersUsed = 99;
        print('[Tutor] ✅ GPU OK');
      } catch (e) {
        print('[Tutor] ⚠️ GPU falló: $e. Cayendo a CPU.');
      }

// Intento 2 (fallback): CPU puro.
      if (result == null || !result.containsKey('contextId')) {
        print('[Tutor] Cargando con CPU...');
        result = await Fllama.instance()!.initContext(
          path,
          nCtx: _contextSize,
          nGpuLayers: 0,
        );
        gpuLayersUsed = 0;
      }

      if (result == null || !result.containsKey('contextId')) {
        throw Exception('Failed to initialize model context. Got: $result');
      }

      _contextId = (result['contextId'] as num).toDouble();
      print('[Tutor] Modelo cargado. GPU layers: $gpuLayersUsed');
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

  /// Descarga el .gguf usando 4 conexiones HTTP paralelas (Range requests).
  ///
  /// HuggingFace soporta `Range: bytes=X-Y` así que partimos el archivo
  /// en N pedazos y los descargamos al mismo tiempo. Esto satura mejor el
  /// ancho de banda que una sola conexión (que típicamente queda limitada
  /// por TCP slow start + latencia).
  ///
  /// Estrategia:
  ///   1. HEAD request → obtener Content-Length.
  ///   2. Crear un archivo "sparse" del tamaño final (con un byte al final).
  ///   3. Lanzar 4 descargas paralelas, cada una escribiendo en su offset.
  ///   4. Esperar a que todas terminen.
  ///   5. Renombrar .partial → definitivo.
  Future<void> _downloadModel(String savePath) async {
    const int numConnections = 4;

    final partialPath = '$savePath.partial';
    final partialFile = File(partialPath);
    if (await partialFile.exists()) {
      await partialFile.delete();
    }

    final client = http.Client();
    try {
      // 1. HEAD para conocer tamaño.
      final headReq = await client.head(Uri.parse(_modelUrl));
      if (headReq.statusCode != 200 && headReq.statusCode != 206) {
        // Fallback: si HEAD no funciona, descarga secuencial tradicional.
        print('[Tutor] HEAD no soportado, usando descarga secuencial');
        await _downloadModelSequential(savePath);
        return;
      }

      final totalBytes =
          int.tryParse(headReq.headers['content-length'] ?? '0') ?? 0;
      if (totalBytes == 0) {
        throw Exception('Tamaño del modelo desconocido');
      }

      // Algunos servidores no soportan Range. Verificamos por `Accept-Ranges`.
      final acceptsRanges = headReq.headers['accept-ranges'] == 'bytes';
      if (!acceptsRanges) {
        print('[Tutor] Servidor no acepta Range, usando descarga secuencial');
        await _downloadModelSequential(savePath);
        return;
      }

      // 2. Crear archivo "sparse" del tamaño total.
      final raf = await partialFile.open(mode: FileMode.write);
      await raf.setPosition(totalBytes - 1);
      await raf.writeByte(0);
      await raf.close();

      // 3. Lanzar descargas paralelas.
      final chunkSize = (totalBytes / numConnections).ceil();
      final progress = List<int>.filled(numConnections, 0);

      final futures = <Future<void>>[];
      for (int i = 0; i < numConnections; i++) {
        final start = i * chunkSize;
        final end = (i == numConnections - 1)
            ? totalBytes - 1
            : (start + chunkSize - 1);
        final idx = i;

        futures.add(_downloadChunk(
          client: client,
          url: _modelUrl,
          savePath: partialPath,
          start: start,
          end: end,
          onProgress: (bytesInChunk) {
            progress[idx] = bytesInChunk;
            final downloaded = progress.fold<int>(0, (a, b) => a + b);
            _statusController.add(
              ModelDownloadStatus(
                stage: ModelDownloadStage.downloading,
                bytesDownloaded: downloaded,
                totalBytes: totalBytes,
              ),
            );
          },
        ));
      }

      await Future.wait(futures);

      // 4. Renombrar.
      await partialFile.rename(savePath);
    } finally {
      client.close();
    }
  }

  /// Descarga un rango de bytes usando HTTP Range.
  Future<void> _downloadChunk({
    required http.Client client,
    required String url,
    required String savePath,
    required int start,
    required int end,
    required void Function(int bytesInChunk) onProgress,
  }) async {
    final req = http.Request('GET', Uri.parse(url));
    req.headers['Range'] = 'bytes=$start-$end';

    final response = await client.send(req);
    if (response.statusCode != 206 && response.statusCode != 200) {
      throw Exception('Chunk falló: HTTP ${response.statusCode}');
    }

    // Importante: abrir el archivo en modo write Y mantener la posición.
    // Usamos RandomAccessFile para poder seek al offset exacto del chunk.
    final raf = await File(savePath).open(mode: FileMode.writeOnly);
    int written = 0;

    try {
      await raf.setPosition(start);

      await for (final bytes in response.stream) {
        await raf.writeFrom(bytes);
        written += bytes.length;
        onProgress(written);
      }
    } finally {
      await raf.close();
    }
  }

  /// Fallback: descarga clásica en una sola conexión.
  /// Se usa si el servidor no soporta Range (no debería pasar con HF).
  Future<void> _downloadModelSequential(String savePath) async {
    final partialPath = '$savePath.partial';
    final partialFile = File(partialPath);
    if (await partialFile.exists()) await partialFile.delete();

    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(_modelUrl));
      final response = await client.send(req);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
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

  /// Construye el prompt usando el chat template de Gemma 2.
  /// Evitamos llamar getFormattedChat() porque tiene un bug en el código
  /// nativo Kotlin (ClassCastException: ArrayList cannot be cast to HashMap[]).
  String _buildGemmaPrompt({
    required String systemPrompt,
    required List<ChatMessage> history,
  }) {
    final buffer = StringBuffer();

    // Gemma 2 incluye el system prompt dentro del primer turno de usuario.
    // Formato: <start_of_turn>user\n{system}\n\n{mensaje}<end_of_turn>
    final userMessages = history.where((m) => !m.isSystem).toList();

    for (int i = 0; i < userMessages.length; i++) {
      final m = userMessages[i];
      if (m.isUser) {
        buffer.write('<start_of_turn>user\n');
        // Inyectar system prompt solo en el primer mensaje del usuario
        if (i == 0 && systemPrompt.isNotEmpty) {
          buffer.write('$systemPrompt\n\n');
        }
        buffer.write('${m.content}<end_of_turn>\n');
      } else {
        buffer.write('<start_of_turn>model\n');
        buffer.write('${m.content}<end_of_turn>\n');
      }
    }

    // Turno del modelo sin cerrar → el LLM completa desde aquí
    buffer.write('<start_of_turn>model\n');
    return buffer.toString();
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

    // Construimos el prompt manualmente en Dart (evitamos el bug de getFormattedChat)
    final prompt = _buildGemmaPrompt(
      systemPrompt: systemPrompt,
      history: history,
    );

    final controller = StreamController<String>();
    StreamSubscription<Map<Object?, dynamic>>? sub;

    sub = fllama.onTokenStream?.listen(
      (event) {
        final function = event['function'] as String?;

        if (function == 'completion') {
          final result = event['result'] as Map?;
          if (result == null) return;

          final isDone = result['stop'] == true ||
              result['stopped_eos'] == true ||
              result['stopped_limit'] == true;

          if (isDone) {
            sub?.cancel();
            if (!controller.isClosed) controller.close();
          } else {
            final token = result['token'] as String?;
            if (token != null && token.isNotEmpty) {
              // Filtramos el token de fin de turno si aparece en el stream
              if (!token.contains('<end_of_turn>')) {
                controller.add(token);
              } else {
                // Emitir solo la parte antes del token especial
                final clean = token.split('<end_of_turn>').first;
                if (clean.isNotEmpty) controller.add(clean);
                sub?.cancel();
                if (!controller.isClosed) controller.close();
              }
            }
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
      Fllama.instance()?.releaseAllContexts();
      _contextId = null;
    }
    await _statusController.close();
  }
}
