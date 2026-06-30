import 'package:flutter/material.dart';

import '../../domain/entities/model_download_status.dart';

/// Pantalla intermedia que muestra el progreso de descarga/carga del modelo.
///
/// Aparece la primera vez que el usuario abre el chat, mientras se baja
/// Gemma 2 2B (~1.5 GB) desde HuggingFace. En sesiones siguientes el
/// modelo ya está en disco y esta pantalla solo se ve unos segundos
/// durante la carga a memoria.
class ModelDownloadProgress extends StatelessWidget {
  final ModelDownloadStatus status;
  final VoidCallback? onRetry;

  const ModelDownloadProgress({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Icono grande ──────────────────────────────────────
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              status.isFailed
                  ? Icons.error_outline_rounded
                  : Icons.auto_awesome_rounded,
              size: 40,
              color: status.isFailed ? cs.error : cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),

          // ── Título según etapa ────────────────────────────────
          Text(
            _titleFor(status.stage),
            style: tt.headlineSmall?.copyWith(
              color: cs.onSurface,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // ── Subtítulo ────────────────────────────────────────
          Text(
            _subtitleFor(status),
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // ── Barra de progreso o error ────────────────────────
          const SizedBox(height: 32),
          if (status.stage == ModelDownloadStage.downloading)
            _DownloadBar(status: status)
          else if (status.isFailed)
            _RetryButton(onTap: onRetry)
          else
            CircularProgressIndicator(color: cs.primary),
        ],
      ),
    );
  }

  String _titleFor(ModelDownloadStage stage) {
    switch (stage) {
      case ModelDownloadStage.idle:
      case ModelDownloadStage.checking:
        return 'Preparando tutor IA…';
      case ModelDownloadStage.downloading:
        return 'Descargando tutor IA';
      case ModelDownloadStage.loading:
        return 'Cargando modelo…';
      case ModelDownloadStage.ready:
        return '¡Listo!';
      case ModelDownloadStage.failed:
        return 'No se pudo cargar el tutor';
    }
  }

  String _subtitleFor(ModelDownloadStatus status) {
    switch (status.stage) {
      case ModelDownloadStage.idle:
      case ModelDownloadStage.checking:
        return 'Verificando archivos locales.';
      case ModelDownloadStage.downloading:
        return 'Solo la primera vez. Después funciona offline.\nNo cierres la app.';
      case ModelDownloadStage.loading:
        return 'Esto toma unos segundos.';
      case ModelDownloadStage.ready:
        return 'Tinta AI está listo para responder.';
      case ModelDownloadStage.failed:
        return status.errorMessage ??
            'Revisa tu conexión a internet y vuelve a intentarlo.';
    }
  }
}

class _DownloadBar extends StatelessWidget {
  final ModelDownloadStatus status;
  const _DownloadBar({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: status.progress > 0 ? status.progress : null,
            minHeight: 8,
            backgroundColor: cs.primaryContainer,
            valueColor: AlwaysStoppedAnimation(cs.primary),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          status.totalBytes > 0
              ? '${status.formattedProgress}  ·  ${(status.progress * 100).toStringAsFixed(0)}%'
              : 'Conectando…',
          style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _RetryButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Reintentar'),
      ),
    );
  }
}
