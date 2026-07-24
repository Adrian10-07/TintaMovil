import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../data/services/model_download_service.dart';
import '../../domain/entities/model_download_status.dart';

/// Banner compacto para el ciclo completo: descarga → preparación → listo.
class TutorModelDownloadBanner extends StatelessWidget {
  const TutorModelDownloadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final downloadService = sl<ModelDownloadService>();

    return ListenableBuilder(
      listenable: downloadService,
      builder: (context, _) {
        final status = downloadService.status;

        switch (status.stage) {
          case ModelDownloadStage.idle:
            return const SizedBox.shrink();

          case ModelDownloadStage.checking:
            return const _InfoBanner(
              icon: Icons.search_rounded,
              text: 'Verificando modelo…',
              isIndeterminate: true,
            );

          case ModelDownloadStage.downloading:
            return _DownloadingBanner(status: status);

          case ModelDownloadStage.loading:
            return const _InfoBanner(
              icon: Icons.memory_rounded,
              text: 'Preparando tutor IA…',
              subtitle: 'Esto puede tomar unos segundos',
              isIndeterminate: true,
            );

          case ModelDownloadStage.ready:
            return const _ReadyBanner();

          case ModelDownloadStage.failed:
            return _FailedBanner(
              status: status,
              onRetry: downloadService.startDownload,
            );
        }
      },
    );
  }
}

// ── Descargando ──────────────────────────────────────────────────────────

class _DownloadingBanner extends StatelessWidget {
  final ModelDownloadStatus status;

  const _DownloadingBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return _BannerShell(
      color: cs.primaryContainer.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.download_rounded, size: 20, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Descargando tutor IA…',
                  style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: cs.onSurface)),
            ),
            Text('Puedes navegar libremente',
                style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: status.progress > 0 ? status.progress : null,
              minHeight: 6,
              backgroundColor: cs.surface,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
          if (status.totalBytes > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${status.formattedProgress}  ·  ${(status.progress * 100).toStringAsFixed(0)}%',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          if (status.errorMessage != null) ...[
            const SizedBox(height: 4),
            Text(status.errorMessage!,
                style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

// ── Info genérica (checking, loading) ────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? subtitle;
  final bool isIndeterminate;

  const _InfoBanner({
    required this.icon,
    required this.text,
    this.subtitle,
    this.isIndeterminate = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return _BannerShell(
      color: cs.primaryContainer.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
                ],
              ],
            )),
          ]),
          if (isIndeterminate) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: cs.surface,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── ¡Listo! ──────────────────────────────────────────────────────────────

class _ReadyBanner extends StatefulWidget {
  const _ReadyBanner();

  @override
  State<_ReadyBanner> createState() => _ReadyBannerState();
}

class _ReadyBannerState extends State<_ReadyBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Auto-ocultar después de 3 segundos.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return FadeTransition(
      opacity: _opacity,
      child: _BannerShell(
        color: cs.tertiaryContainer.withOpacity(0.6),
        child: Row(children: [
          Icon(Icons.check_circle_rounded, size: 20, color: cs.tertiary),
          const SizedBox(width: 10),
          Expanded(child: Text('¡Tutor IA listo para usar!',
              style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: cs.onSurface))),
          Icon(Icons.auto_awesome_rounded, size: 16, color: cs.tertiary),
        ]),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────

class _FailedBanner extends StatelessWidget {
  final ModelDownloadStatus status;
  final VoidCallback onRetry;

  const _FailedBanner({required this.status, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return _BannerShell(
      color: cs.errorContainer.withOpacity(0.5),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, size: 20, color: cs.error),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Error al descargar tutor IA',
                style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600, color: cs.onSurface)),
            if (status.errorMessage != null) ...[
              const SizedBox(height: 2),
              Text(status.errorMessage!,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        )),
        const SizedBox(width: 8),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Reintentar')),
      ]),
    );
  }
}

// ── Shell compartido ─────────────────────────────────────────────────────

class _BannerShell extends StatelessWidget {
  final Color color;
  final Widget child;

  const _BannerShell({required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}