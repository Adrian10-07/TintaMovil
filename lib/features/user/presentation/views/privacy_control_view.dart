import 'package:flutter/material.dart';
import '../../../reader/data/services/reading_library_service.dart';
import '../../../reader/data/services/epub_download_service.dart';
import '../../../notifications/data/services/notification_service.dart';
import '../../../recommendations/data/services/recent_documents_service.dart';
import '../../../../core/localization/app_strings.dart';

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
    final t = AppStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.privacy)),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
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
                    t.privacyIntro,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(t.dataStored,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _DataRow(
            icon: Icons.menu_book_rounded,
            title: t.downloadedBooks,
            subtitle: _cacheSizeMb == null
                ? '...'
                : '${_cacheSizeMb!.toStringAsFixed(1)} MB',
            actionLabel: t.delete,
            onAction: () => _confirmAndRun(
              title: t.downloadedBooks,
              message: t.confirmDeleteBooks,
              action: () => EpubDownloadService.clearCache(),
            ),
          ),
          _DataRow(
            icon: Icons.auto_stories_rounded,
            title: t.readingHistory,
            subtitle: t.currentlyReadingSubtitle,
            actionLabel: t.delete,
            onAction: () => _confirmAndRun(
              title: t.readingHistory,
              message: t.confirmDeleteHistory,
              action: () => ReadingLibraryService.clearAll(widget.userId),
            ),
          ),
          _DataRow(
            icon: Icons.description_rounded,
            title: t.recentDocuments,
            subtitle: t.recentDocumentsSubtitle,
            actionLabel: t.delete,
            onAction: () => _confirmAndRun(
              title: t.recentDocuments,
              message: t.confirmDeleteDocuments,
              action: () => RecentDocumentsService.clearAll(widget.userId),
            ),
          ),
          _DataRow(
            icon: Icons.notifications_rounded,
            title: t.notifications,
            subtitle: t.notificationsHistorySubtitle,
            actionLabel: t.delete,
            onAction: () => _confirmAndRun(
              title: t.notifications,
              message: t.confirmDeleteNotifications,
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