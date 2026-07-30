import 'dart:async';

import 'package:flutter/material.dart';

import 'package:tinta/core/di/service_locator.dart';

import '../../../tutorAI/data/datasources/remote_tutor_datasource.dart';
import '../../../tutorAI/domain/entities/remote_document.dart';
import '../../../tutorAI/presentation/components/document_indexing_screen.dart';

/// Sheet que se muestra mientras el backend termina de indexar un PDF para
/// el tutor de IA. 
class IndexingSheetHost extends StatefulWidget {
  final RemoteDocument initialDoc;
  final void Function(RemoteDocument ready) onReady;
  final VoidCallback onRetryUpload;

  const IndexingSheetHost({
    super.key,
    required this.initialDoc,
    required this.onReady,
    required this.onRetryUpload,
  });

  @override
  State<IndexingSheetHost> createState() => _IndexingSheetHostState();
}

class _IndexingSheetHostState extends State<IndexingSheetHost> {
  late RemoteDocument _doc;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _doc = widget.initialDoc;
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    if (_doc.status.isTerminal) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      try {
        final updated =
        await sl<RemoteTutorDatasource>().getDocumentStatus(_doc.id);
        if (!mounted) return;
        setState(() => _doc = updated);
        if (updated.isReady) {
          t.cancel();
          widget.onReady(updated);
        } else if (updated.isFailed) {
          t.cancel();
        }
      } catch (_) {
        // Errores transitorios: seguimos intentando en el siguiente tick.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DocumentIndexingScreen(
      document: _doc,
      onCancel: () => Navigator.of(context).pop(),
      onRetry: widget.onRetryUpload,
    );
  }
}