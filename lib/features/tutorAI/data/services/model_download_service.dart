import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/model_download_status.dart';
import '../datasources/tutor_llm_datasource.dart';

/// Servicio puente entre el datasource del tutor y la UI.
///
/// NO descarga el modelo por su cuenta — delega a [TutorLlmDatasource]
/// (que internamente usa flutter_gemma con su propio downloader).
///
/// Lo que SÍ hace:
/// - Expone el estado como ChangeNotifier (para ListenableBuilder en el banner).
/// - Permite pausar la inicialización y reintentar.
/// - Maneja el caso offline correctamente.
/// - Sin timeout artificial — la descarga toma el tiempo que necesite.
class ModelDownloadService extends ChangeNotifier {
  final TutorLlmDatasource _datasource;

  ModelDownloadStatus _status =
  const ModelDownloadStatus(stage: ModelDownloadStage.idle);
  ModelDownloadStatus get status => _status;

  StreamSubscription<ModelDownloadStatus>? _sub;
  bool _isStarting = false;

  /// Token de HuggingFace (no se usa aquí — el datasource ya lo tiene).
  String? huggingFaceToken;

  ModelDownloadService(this._datasource) {
    // Escuchar el stream del datasource y re-emitir como ChangeNotifier.
    _sub = _datasource.statusStream.listen((s) {
      _status = s;
      notifyListeners();
    });
  }

  /// Inicia la preparación del modelo (descarga + carga).
  ///
  /// Delega completamente a [TutorLlmDatasource.ensureModelReady()].
  /// Sin timeout — flutter_gemma maneja la descarga con su propio
  /// downloader que soporta background y resume automático.
  Future<void> startDownload() async {
    if (_isStarting) return;
    if (_status.stage == ModelDownloadStage.ready) return;

    _isStarting = true;

    try {
      await _datasource.ensureModelReady();
    } catch (e) {
      debugPrint('ModelDownloadService: ensureModelReady failed: $e');
      // El datasource ya emitió el estado failed via stream.
    } finally {
      _isStarting = false;
    }
  }

  /// Restaura el último estado conocido del datasource.
  Future<void> restoreState() async {
    _status = _datasource.lastStatus;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}