import 'package:flutter/material.dart';

import '../../domain/entities/remote_document.dart';

/// Pantalla que muestra el progreso de indexación de un PDF en el backend.
///
/// Se muestra cuando el usuario toca ✨ pero el PDF aún no está `ready`.
class DocumentIndexingScreen extends StatelessWidget {
  final RemoteDocument document;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const DocumentIndexingScreen({
    super.key,
    required this.document,
    this.onRetry,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isFailed = document.isFailed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: isFailed ? cs.errorContainer : cs.primaryContainer,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              isFailed
                  ? Icons.error_outline_rounded
                  : Icons.menu_book_rounded,
              size: 44,
              color: isFailed ? cs.error : cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            isFailed
                ? 'No se pudo preparar el documento'
                : 'Preparando el tutor…',
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            isFailed
                ? (document.errorMessage ??
                'Ocurrió un error durante el procesamiento del PDF.')
                : 'Estamos analizando "${document.filename}".\nEsto toma entre 30 y 90 segundos.',
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          if (isFailed)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onCancel != null)
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancelar'),
                  ),
                const SizedBox(width: 12),
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
              ],
            )
          else
            Column(
              children: [
                CircularProgressIndicator(color: cs.primary),
                const SizedBox(height: 16),
                Text(
                  _statusText(document),
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _statusText(RemoteDocument doc) {
    switch (doc.status) {
      case RemoteDocumentStatus.pending:
        return 'En cola de procesamiento…';
      case RemoteDocumentStatus.processing:
        return 'Extrayendo texto y generando embeddings…';
      case RemoteDocumentStatus.ready:
        return 'Listo';
      case RemoteDocumentStatus.failed:
        return 'Falló';
    }
  }
}
