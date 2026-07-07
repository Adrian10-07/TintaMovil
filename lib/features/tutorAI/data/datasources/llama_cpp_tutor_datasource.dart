import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import 'tutor_llm_datasource.dart';

class LlamaCppTutorDatasource implements TutorLlmDatasource {
  static const String _modelUrl =
      'https://huggingface.co/bartowski/google_gemma-3-1b-it-GGUF/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf';
  static const String _modelFileName = 'google_gemma-3-1b-it-Q4_K_M.gguf';

  static const int _contextSize = 2048;
  static const double _temperature = 0.7;
  static const double _topP = 0.9;

  final StreamController<ModelDownloadStatus> _statusController =
      StreamController<ModelDownloadStatus>.broadcast();

  LlamaParent? _llamaParent;
  bool _isReady = false;
  bool _isInitializing = false;
  StreamSubscription<String>? _tokenSubscription;
  StreamController<String>? _generateController;

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

      final dir = await getApplicationDocumentsDirectory();
      final oldModelFile = File('${dir.path}/gemma-2-2b-it-q4_k_m.gguf');
      if (await oldModelFile.exists()) {
        // Eliminando modelo anterior de Gemma 2 2B...
        await oldModelFile.delete();
      }
      final oldPartialFile = File('${dir.path}/gemma-2-2b-it-q4_k_m.gguf.partial');
      if (await oldPartialFile.exists()) {
        await oldPartialFile.delete();
      }

      final path = await _resolveModelPath();
      final file = File(path);

      if (!await file.exists()) {
        await _downloadModel(path);
      } else {
        final client = http.Client();
        try {
          final headReq = await client.head(Uri.parse(_modelUrl));
          final expectedSize = int.tryParse(headReq.headers['content-length'] ?? '0') ?? 0;
          if (expectedSize > 0) {
            final size = await file.length();
            if (size != expectedSize) {
              // Modelo corrupto. Redescargando...
              await file.delete();
              await _downloadModel(path);
            }
          }
        } catch (e) {
          final size = await file.length();
          if (size < 500 * 1024 * 1024) {
            await file.delete();
            await _downloadModel(path);
          }
        } finally {
          client.close();
        }
      }

      _statusController.add(
        const ModelDownloadStatus(stage: ModelDownloadStage.loading),
      );

      // Cargando modelo con llama_cpp_dart...
      
      final modelParams = ModelParams()..nGpuLayers = 0;
      final contextParams = ContextParams()..nCtx = _contextSize;
      final samplingParams = SamplerParams()
        ..temp = _temperature
        ..topP = _topP;

      final loadCommand = LlamaLoad(
        path: path,
        modelParams: modelParams,
        contextParams: contextParams,
        samplingParams: samplingParams,
      );

      _llamaParent = LlamaParent(loadCommand);
      await _llamaParent!.init();

      _tokenSubscription = _llamaParent!.stream.listen(
        (response) {
          if (response == '[DONE]') {
            // Placeholder for done condition
          } else {
            _generateController?.add(response);
          }
        },
        onDone: () => _generateController?.close(),
        onError: (e) => _generateController?.addError(e),
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

  Future<void> _downloadModel(String savePath) async {
    const int numConnections = 4;
    final partialPath = '$savePath.partial';
    final partialFile = File(partialPath);
    if (await partialFile.exists()) {
      await partialFile.delete();
    }

    final client = http.Client();
    try {
      final headReq = await client.head(Uri.parse(_modelUrl));
      if (headReq.statusCode != 200 && headReq.statusCode != 206) {
        await _downloadModelSequential(savePath);
        return;
      }

      final totalBytes = int.tryParse(headReq.headers['content-length'] ?? '0') ?? 0;
      if (totalBytes == 0) throw Exception('Tamaño desconocido');

      final acceptsRanges = headReq.headers['accept-ranges'] == 'bytes';
      if (!acceptsRanges) {
        await _downloadModelSequential(savePath);
        return;
      }

      final raf = await partialFile.open(mode: FileMode.write);
      await raf.setPosition(totalBytes - 1);
      await raf.writeByte(0);
      await raf.close();

      final chunkSize = (totalBytes / numConnections).ceil();
      final progress = List<int>.filled(numConnections, 0);
      final futures = <Future<void>>[];

      for (int i = 0; i < numConnections; i++) {
        final start = i * chunkSize;
        final end = (i == numConnections - 1) ? totalBytes - 1 : (start + chunkSize - 1);
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
      final finalSize = await partialFile.length();
      if (finalSize != totalBytes) {
        throw Exception('Descarga corrupta');
      }
      await partialFile.rename(savePath);
    } finally {
      client.close();
    }
  }

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
      throw Exception('Chunk falló: ${response.statusCode}');
    }
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

  Future<void> _downloadModelSequential(String savePath) async {
    final partialPath = '$savePath.partial';
    final partialFile = File(partialPath);
    if (await partialFile.exists()) await partialFile.delete();
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(_modelUrl));
      final response = await client.send(req);
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
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

  String _buildGemmaPrompt({
    required String systemPrompt,
    required List<ChatMessage> history,
  }) {
    final buffer = StringBuffer();
    final userMessages = history.where((m) => !m.isSystem).toList();
    for (int i = 0; i < userMessages.length; i++) {
      final m = userMessages[i];
      if (m.isUser) {
        buffer.write('<start_of_turn>user\n');
        if (i == 0 && systemPrompt.isNotEmpty) {
          buffer.write('$systemPrompt\n\n');
        }
        buffer.write('${m.content}<end_of_turn>\n');
      } else {
        buffer.write('<start_of_turn>model\n');
        buffer.write('${m.content}<end_of_turn>\n');
      }
    }
    buffer.write('<start_of_turn>model\n');
    return buffer.toString();
  }

  @override
  Stream<String> generate({
    required String systemPrompt,
    required List<ChatMessage> history,
  }) async* {
    if (!_isReady || _llamaParent == null) {
      throw StateError('Modelo no listo.');
    }

    final prompt = _buildGemmaPrompt(
      systemPrompt: systemPrompt,
      history: history,
    );

    if (_generateController != null && !_generateController!.isClosed) {
      _generateController!.close();
    }

    _generateController = StreamController<String>();
    
    _llamaParent!.sendPrompt(prompt);

    await for (final token in _generateController!.stream) {
      if (token == '[DONE]') break;
      if (!token.contains('<end_of_turn>')) {
        yield token;
      } else {
        final clean = token.split('<end_of_turn>').first;
        if (clean.isNotEmpty) yield clean;
        break;
      }
    }
  }

  @override
  Future<void> deleteModel() async {
    final path = await _resolveModelPath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _isReady = false;
    _statusController.add(
      const ModelDownloadStatus(stage: ModelDownloadStage.idle),
    );
  }

  @override
  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    _llamaParent?.stop();
    _llamaParent = null;
    await _statusController.close();
  }
}
