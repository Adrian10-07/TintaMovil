import 'package:flutter/material.dart';
import '../../../reader/data/services/reading_library_service.dart';
import '../../../reader/data/services/epub_download_service.dart';
import '../../../notifications/data/services/notification_service.dart';
import '../../../recommendations/data/services/recent_documents_service.dart';

/// Pantalla "Privacidad" — explica qué se guarda dónde, y da control real
/// para borrar cada tipo de dato guardado localmente en el dispositivo.
class PrivacyControlView extends StatefulWidget {
  final String userId;
  const PrivacyControlView({Key? key, required this.userId}) : super(key: key);

  @override
  State<PrivacyControlView> createState() => _PrivacyControlViewState();
}

class _PrivacyControlViewState extends State<PrivacyControlView> {
  double? _cacheSizeMb;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    final size = await EpubDownloadService.cacheSizeMb();
    if (mounted) setState(() => _cacheSizeMb = size);
  }

  Future<void> _confirmAndRun({
    required String title,
    required String message,
    required Future<void> Function() action,
  }) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    await action();
    _loadCacheSize();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listo — se borró correctamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Privacidad')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tu racha, historial de lectura, notificaciones y libros '
                        'descargados se guardan solo en este dispositivo. Los '
                        'PDF que subes para análisis sí viajan al servidor de '
                        'Tinta por HTTPS (necesario para generar recomendaciones), '
                        'pero nada de lo de aquí abajo se comparte con nadie más.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Datos guardados en este dispositivo',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _DataRow(
            icon: Icons.menu_book_rounded,
            title: 'Libros descargados (caché)',
            subtitle: _cacheSizeMb == null
                ? 'Calculando...'
                : '${_cacheSizeMb!.toStringAsFixed(1)} MB en el dispositivo',
            actionLabel: 'Borrar',
            onAction: () => _confirmAndRun(
              title: 'Borrar libros descargados',
              message: 'Se borran las copias locales de los EPUB. La próxima vez que abras cada uno, se vuelve a descargar (necesitas conexión esa primera vez).',
              action: () => EpubDownloadService.clearCache(),
            ),
          ),
          _DataRow(
            icon: Icons.auto_stories_rounded,
            title: 'Historial de lectura',
            subtitle: 'Progreso guardado de "Leyendo actualmente"',
            actionLabel: 'Borrar',
            onAction: () => _confirmAndRun(
              title: 'Borrar historial de lectura',
              message: 'Se borra tu progreso guardado en todos los libros. No se puede deshacer.',
              action: () => ReadingLibraryService.clearAll(widget.userId),
            ),
          ),
          _DataRow(
            icon: Icons.description_rounded,
            title: 'Documentos recientes',
            subtitle: 'Lista de PDFs subidos en Estudio',
            actionLabel: 'Borrar',
            onAction: () => _confirmAndRun(
              title: 'Borrar documentos recientes',
              message: 'Se borra la lista de "Recientes" (no borra los PDF de tu dispositivo, solo la lista dentro de Tinta).',
              action: () => RecentDocumentsService.clearAll(widget.userId),
            ),
          ),
          _DataRow(
            icon: Icons.notifications_rounded,
            title: 'Notificaciones',
            subtitle: 'Historial de la bandeja de notificaciones',
            actionLabel: 'Borrar',
            onAction: () => _confirmAndRun(
              title: 'Borrar notificaciones',
              message: 'Se borra tu bandeja de notificaciones completa.',
              action: () => NotificationService.clearAll(widget.userId),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _DataRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.55))),
              ],
            ),
          ),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(foregroundColor: colorScheme.error),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}