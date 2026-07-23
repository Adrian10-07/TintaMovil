// import 'dart:async';
// import 'dart:io';
//
// import 'package:http/http.dart' as http;
// import 'package:path_provider/path_provider.dart';
// import 'package:llama_cpp_dart/llama_cpp_dart.dart' hide ChatMessage;
//
// import '../../domain/entities/chat_message.dart';
// import '../../domain/entities/model_download_status.dart';
// import 'tutor_llm_datasource.dart';
//
// /// Datasource que usa llama_cpp_dart 0.9.x (LlamaEngine API)
// /// con libs nativas compiladas localmente desde el tag b9360 de llama.cpp
// /// y colocadas en android/app/src/main/jniLibs/arm64-v8a/.
// ///
// /// Compiladas con -march=armv8-a (baseline ARM64) para compatibilidad
// /// con TODOS los dispositivos arm64.
// class LlamaCppTutorDatasource implements TutorLlmDatasource {
//   static const String _modelUrl =
//       'https://huggingface.co/bartowski/google_gemma-3-1b-it-GGUF/resolve/main/google_gemma-3-1b-it-Q4_K_M.gguf';
//   static const String _modelFileName = 'google_gemma-3-1b-it-Q4_K_M.gguf';
//
//   // Conservador para dispositivos con 4-6GB RAM (A52s, etc.).
//   // Subir a 2048 solo en dispositivos con >=8GB.
//   static const int _contextSize = 1024;
//   static const double _temperature = 0.7;
//   static const double _topP = 0.9;
//
//   final StreamController<ModelDownloadStatus> _statusController =
//   StreamController<ModelDownloadStatus>.broadcast();
//
//   LlamaEngine? _engine;
//   bool _isReady = false;
//   bool _isInitializing = false;
//
//   @override
//   Stream<ModelDownloadStatus> get statusStream => _statusController.stream;
//
//   Future<String> _resolveModelPath() async {
//     final dir = await getApplicationDocumentsDirectory();
//     return '${dir.path}/$_modelFileName';
//   }
//
//   @override
//   Future<void> ensureModelReady() async {
//     if (_isReady) return;
//     if (_isInitializing) return;
//     _isInitializing = true;
//
//     try {
//       _statusController.add(
//         const ModelDownloadStatus(stage: ModelDownloadStage.checking),
//       );
//
//       // Limpiar modelo anterior si existe.
//       final dir = await getApplicationDocumentsDirectory();
//       final oldModelFile = File('${dir.path}/gemma-2-2b-it-q4_k_m.gguf');
//       if (await oldModelFile.exists()) await oldModelFile.delete();
//       final oldPartialFile =
//       File('${dir.path}/gemma-2-2b-it-q4_k_m.gguf.partial');
//       if (await oldPartialFile.exists()) await oldPartialFile.delete();
//
//       final path = await _resolveModelPath();
//       final file = File(path);
//
//       if (!await file.exists()) {
//         await _downloadModel(path);
//       } else {
//         // Verificar integridad del modelo descargado.
//         final client = http.Client();
//         try {
//           final headReq = await client.head(Uri.parse(_modelUrl));
//           final expectedSize =
//               int.tryParse(headReq.headers['content-length'] ?? '0') ?? 0;
//           if (expectedSize > 0) {
//             final size = await file.length();
//             if (size != expectedSize) {
//               await file.delete();
//               await _downloadModel(path);
//             }
//           }
//         } catch (e) {
//           final size = await file.length();
//           if (size < 500 * 1024 * 1024) {
//             await file.delete();
//             await _downloadModel(path);
//           }
//         } finally {
//           client.close();
//         }
//       }
//
//       _statusController.add(
//         const ModelDownloadStatus(stage: ModelDownloadStage.loading),
//       );
//
//       // ── Inicializar LlamaEngine (0.9.x API) ──────────────────────────
//       // Android resuelve libllama.so desde jniLibs/arm64-v8a/ por basename.
//       _engine = await LlamaEngine.spawn(
//         libraryPath: 'libllama.so',
//         modelParams: ModelParams(
//           path: path,
//           gpuLayers: 0, // CPU only en Android.
//         ),
//         contextParams: ContextParams(nCtx: _contextSize),
//       );
//
//       _isReady = true;
//       _statusController.add(
//         const ModelDownloadStatus(stage: ModelDownloadStage.ready),
//       );
//     } catch (e) {
//       _statusController.add(
//         ModelDownloadStatus(
//           stage: ModelDownloadStage.failed,
//           errorMessage: e.toString(),
//         ),
//       );
//       rethrow;
//     } finally {
//       _isInitializing = false;
//     }
//   }
//
//   // ── Descarga paralela ─────────────────────────────────────────────────
//
//   Future<void> _downloadModel(String savePath) async {
//     const int numConnections = 4;
//     final partialPath = '$savePath.partial';
//     final partialFile = File(partialPath);
//     if (await partialFile.exists()) await partialFile.delete();
//
//     final client = http.Client();
//     try {
//       final headReq = await client.head(Uri.parse(_modelUrl));
//       if (headReq.statusCode != 200 && headReq.statusCode != 206) {
//         await _downloadModelSequential(savePath);
//         return;
//       }
//
//       final totalBytes =
//           int.tryParse(headReq.headers['content-length'] ?? '0') ?? 0;
//       if (totalBytes == 0) throw Exception('Tamaño desconocido');
//
//       final acceptsRanges = headReq.headers['accept-ranges'] == 'bytes';
//       if (!acceptsRanges) {
//         await _downloadModelSequential(savePath);
//         return;
//       }
//
//       final raf = await partialFile.open(mode: FileMode.write);
//       await raf.setPosition(totalBytes - 1);
//       await raf.writeByte(0);
//       await raf.close();
//
//       final chunkSize = (totalBytes / numConnections).ceil();
//       final progress = List<int>.filled(numConnections, 0);
//       final futures = <Future<void>>[];
//
//       for (int i = 0; i < numConnections; i++) {
//         final start = i * chunkSize;
//         final end = (i == numConnections - 1)
//             ? totalBytes - 1
//             : (start + chunkSize - 1);
//         final idx = i;
//
//         futures.add(_downloadChunk(
//           client: client,
//           url: _modelUrl,
//           savePath: partialPath,
//           start: start,
//           end: end,
//           onProgress: (bytesInChunk) {
//             progress[idx] = bytesInChunk;
//             final downloaded = progress.fold<int>(0, (a, b) => a + b);
//             _statusController.add(
//               ModelDownloadStatus(
//                 stage: ModelDownloadStage.downloading,
//                 bytesDownloaded: downloaded,
//                 totalBytes: totalBytes,
//               ),
//             );
//           },
//         ));
//       }
//
//       await Future.wait(futures);
//       final finalSize = await partialFile.length();
//       if (finalSize != totalBytes) throw Exception('Descarga corrupta');
//       await partialFile.rename(savePath);
//     } finally {
//       client.close();
//     }
//   }
//
//   Future<void> _downloadChunk({
//     required http.Client client,
//     required String url,
//     required String savePath,
//     required int start,
//     required int end,
//     required void Function(int bytesInChunk) onProgress,
//   }) async {
//     final req = http.Request('GET', Uri.parse(url));
//     req.headers['Range'] = 'bytes=$start-$end';
//     final response = await client.send(req);
//     if (response.statusCode != 206 && response.statusCode != 200) {
//       throw Exception('Chunk falló: ${response.statusCode}');
//     }
//     final raf = await File(savePath).open(mode: FileMode.writeOnly);
//     int written = 0;
//     try {
//       await raf.setPosition(start);
//       await for (final bytes in response.stream) {
//         await raf.writeFrom(bytes);
//         written += bytes.length;
//         onProgress(written);
//       }
//     } finally {
//       await raf.close();
//     }
//   }
//
//   Future<void> _downloadModelSequential(String savePath) async {
//     final partialPath = '$savePath.partial';
//     final partialFile = File(partialPath);
//     if (await partialFile.exists()) await partialFile.delete();
//     final client = http.Client();
//     try {
//       final req = http.Request('GET', Uri.parse(_modelUrl));
//       final response = await client.send(req);
//       if (response.statusCode != 200) {
//         throw Exception('HTTP ${response.statusCode}');
//       }
//       final totalBytes = response.contentLength ?? 0;
//       int bytesDownloaded = 0;
//       final sink = partialFile.openWrite();
//       await for (final chunk in response.stream) {
//         sink.add(chunk);
//         bytesDownloaded += chunk.length;
//         _statusController.add(
//           ModelDownloadStatus(
//             stage: ModelDownloadStage.downloading,
//             bytesDownloaded: bytesDownloaded,
//             totalBytes: totalBytes,
//           ),
//         );
//       }
//       await sink.flush();
//       await sink.close();
//       await partialFile.rename(savePath);
//     } finally {
//       client.close();
//     }
//   }
//
//   // ── Generación con EngineChat (0.9.x) ─────────────────────────────────
//
//   @override
//   Stream<String> generate({
//     required String systemPrompt,
//     required List<ChatMessage> history,
//   }) async* {
//     if (!_isReady || _engine == null) {
//       throw StateError('Modelo no listo.');
//     }
//
//     // EngineChat aplica automáticamente el chat template del modelo
//     // (Gemma detectado via llama_chat_apply_template).
//     final chat = await _engine!.createChat();
//
//     // 1. System prompt.
//     chat.addSystem(systemPrompt);
//
//     // 2. Historial de mensajes (sin system ni streaming).
//     final userMessages =
//     history.where((m) => !m.isSystem && !m.isStreaming).toList();
//     for (final m in userMessages) {
//       if (m.isUser) {
//         chat.addUser(m.content);
//       } else if (m.isAssistant) {
//         chat.addAssistant(m.content);
//       }
//     }
//
//     // 3. Generar respuesta en streaming.
//     // Con contexto de 1024, prompt+historial ocupa ~500-700 tokens,
//     // así que limitamos la generación a 256 para no exceder el buffer.
//     await for (final event in chat.generate(
//       maxTokens: 256,
//       sampler: SamplerParams(
//         temperature: _temperature,
//         topP: _topP,
//       ),
//     )) {
//       switch (event) {
//         case TokenEvent():
//           yield event.text;
//         case ShiftEvent():
//         // Context shift — ignorar silenciosamente.
//           break;
//         case DoneEvent():
//         // Generación terminada.
//           break;
//       }
//     }
//
//     // Liberar la sesión de chat.
//     await chat.dispose();
//   }
//
//   @override
//   Future<void> deleteModel() async {
//     final path = await _resolveModelPath();
//     final file = File(path);
//     if (await file.exists()) await file.delete();
//     _isReady = false;
//     _statusController.add(
//       const ModelDownloadStatus(stage: ModelDownloadStage.idle),
//     );
//   }
//
//   @override
//   Future<void> dispose() async {
//     await _engine?.dispose();
//     _engine = null;
//     await _statusController.close();
//   }
// }

// Comentado temporalmente para poder compilar sin llama_cpp_dart.
// Se restaurará cuando se active el modo offline.

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/model_download_status.dart';
import 'tutor_llm_datasource.dart';

class LlamaCppTutorDatasource implements TutorLlmDatasource {
  @override
  Stream<ModelDownloadStatus> get statusStream => const Stream.empty();

  @override
  Future<void> ensureModelReady() async {
    throw UnimplementedError('Modo offline no disponible en esta build.');
  }

  @override
  Stream<String> generate({
    required String systemPrompt,
    required List<ChatMessage> history,
  }) async* {
    throw UnimplementedError('Modo offline no disponible en esta build.');
  }

  @override
  Future<void> deleteModel() async {}

  @override
  Future<void> dispose() async {}
}