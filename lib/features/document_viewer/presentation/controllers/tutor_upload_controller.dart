import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../../../tutorAI/data/datasources/remote_tutor_datasource.dart';
import '../../../tutorAI/domain/entities/remote_document.dart';
import '../../../tutorAI/domain/repositories/document_registry.dart';

/// Orquesta el ciclo de vida del documento en el tutor remoto: calcular su
/// hash, subirlo (o recuperar un `document_id` ya conocido), y hacer polling
/// hasta que termine de indexarse.

class TutorUploadController extends ChangeNotifier {
  final RemoteTutorDatasource _datasource;
  final DocumentRegistry _registry;

  TutorUploadController({
    required RemoteTutorDatasource datasource,
    required DocumentRegistry registry,
  })  : _datasource = datasource,
        _registry = registry;

  RemoteDocument? _remoteDocument;
  RemoteDocument? get remoteDocument => _remoteDocument;

  String? _error;
  String? get error => _error;

  bool _uploadInProgress = false;
  Timer? _pollingTimer;

  File? _file;
  String? _fileName;

  /// Punto de entrada único: calcula el hash del PDF y decide si hay que
  /// subirlo de nuevo o solo consultar el estado de una subida anterior.
  Future<void> initialize({required File file, required String fileName}) async {
    _file = file;
    _fileName = fileName;

    try {
      final hash = await _computeSha256(file);
      final existingId = await _registry.getDocumentIdByHash(hash);

      if (existingId != null) {
        await _refreshRemoteDocument(existingId);
        _startPollingIfNeeded();
        return;
      }

      await _uploadDocument(hash);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> retryUpload() async {
    final file = _file;
    if (file == null) return;

    final hash = await _computeSha256(file);
    await _registry.removeByHash(hash);
    _remoteDocument = null;
    notifyListeners();
    await _uploadDocument(hash);
  }

  Future<void> _uploadDocument(String hash) async {
    if (_uploadInProgress) return;
    _uploadInProgress = true;

    try {
      final doc = await _datasource.uploadDocument(_file!);
      await _registry.saveMapping(
        hash: hash,
        documentId: doc.id,
        filename: _fileName ?? '',
      );

      _remoteDocument = doc;
      notifyListeners();
      _startPollingIfNeeded();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _uploadInProgress = false;
    }
  }

  Future<void> _refreshRemoteDocument(String documentId) async {
    try {
      final doc = await _datasource.getDocumentStatus(documentId);
      _remoteDocument = doc;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _startPollingIfNeeded() {
    _pollingTimer?.cancel();
    final doc = _remoteDocument;
    if (doc == null || doc.status.isTerminal) return;

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _refreshRemoteDocument(doc.id);
      final updated = _remoteDocument;
      if (updated == null || updated.status.isTerminal) {
        timer.cancel();
      }
    });
  }

  Future<String> _computeSha256(File file) async {
    // Streaming hash: no cargamos el PDF entero a memoria.
    final stream = file.openRead();
    final digest = await stream.transform(sha256).single;
    return digest.toString();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}