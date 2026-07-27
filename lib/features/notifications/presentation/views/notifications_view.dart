import 'package:flutter/material.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';
import '../../data/services/notification_service.dart';

class NotificationsView extends StatefulWidget {
  final String userId;

  const NotificationsView({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  List<AppNotification>? _notifications;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await NotificationService.markAllRead(widget.userId);
    final items = await NotificationService.getAll(widget.userId);
    if (mounted) setState(() => _notifications = items);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: _notifications == null
          ? const Center(child: CircularProgressIndicator())
          : _notifications!.isEmpty
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_off_outlined,
                  size: 48, color: colorScheme.onSurface.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(
                'Todavía no tienes notificaciones.\nAparecerán aquí tus rachas y '
                    'recomendaciones nuevas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
              ),
            ],
          ),
        ),
      )
          : ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        itemCount: _notifications!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final n = _notifications![index];
          return _NotificationTile(notification: n);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'recommendation':
        return Icons.auto_awesome_rounded;
      case 'upload':
        return Icons.upload_file_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _iconColor(ColorScheme colorScheme) {
    switch (notification.type) {
      case 'streak':
        return MaterialTheme.amber;
      case 'recommendation':
        return colorScheme.primary;
      case 'upload':
        return colorScheme.tertiary;
      default:
        return colorScheme.onSurface;
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(notification.createdAt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return 'hace ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconColor(colorScheme).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: _iconColor(colorScheme), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  notification.body,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.4),
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