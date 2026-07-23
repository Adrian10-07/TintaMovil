import 'package:flutter/material.dart';

import 'package:tinta/core/di/service_locator.dart';
import '../../../tutorAI/data/datasources/tutor_llm_datasource.dart';
import '../../../tutorAI/domain/entities/model_download_status.dart';

/// Barra compacta que se muestra en Home mientras Gemma se descarga en
/// segundo plano (disparado desde main.dart al abrir la app). Se oculta
/// sola cuando el modelo queda listo, falla, o está inactivo.
///
/// Escucha el MISMO datasource singleton que usa el chat local, así que
/// si el usuario abre el chat a mitad de la descarga, ve exactamente el
/// mismo progreso sin duplicar la descarga ni perder el estado.
class TutorModelDownloadBanner extends StatefulWidget {
  const TutorModelDownloadBanner({super.key});

  @override
  State<TutorModelDownloadBanner> createState() =>
      _TutorModelDownloadBannerState();
}

class _TutorModelDownloadBannerState extends State<TutorModelDownloadBanner> {
  late final TutorLlmDatasource _datasource;
  late ModelDownloadStatus _status;

  @override
  void initState() {
    super.initState();
    _datasource = sl<TutorLlmDatasource>();
    // Estado inicial: si la descarga ya empezó antes de montar este
    // widget (por ejemplo, Home no era la primera pantalla), no hay que
    // esperar el próximo evento del stream para pintar algo correcto.
    _status = _datasource.lastStatus;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ModelDownloadStatus>(
      stream: _datasource.statusStream,
      initialData: _status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? _status;

        // Solo se muestra mientras hay algo relevante que comunicar.
        final isVisible = status.stage == ModelDownloadStage.downloading ||
            status.stage == ModelDownloadStage.loading ||
            status.stage == ModelDownloadStage.checking;

        if (!isVisible) return const SizedBox.shrink();

        return _BannerContent(status: status);
      },
    );
  }
}

class _BannerContent extends StatelessWidget {
  final ModelDownloadStatus status;
  const _BannerContent({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isDownloading = status.stage == ModelDownloadStage.downloading;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 20,
            color: cs.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDownloading
                      ? 'Preparando tutor sin conexión…'
                      : 'Cargando tutor…',
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                if (isDownloading) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: status.progress > 0 ? status.progress : null,
                      minHeight: 6,
                      backgroundColor: cs.surface,
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.totalBytes > 0
                        ? '${status.formattedProgress}  ·  ${(status.progress * 100).toStringAsFixed(0)}%'
                        : 'Conectando…',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ] else
                  SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      backgroundColor: cs.surface,
                      valueColor: AlwaysStoppedAnimation(cs.primary),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
