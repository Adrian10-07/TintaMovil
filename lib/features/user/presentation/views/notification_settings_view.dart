import 'package:flutter/material.dart';
import '../../../notifications/data/services/notification_settings_service.dart';
import '../../../../core/localization/app_strings.dart';

/// Pantalla "Notificaciones" — enciende/apaga cada tipo de notificación
/// in-app real que genera la app (racha, documentos subidos,
/// recomendaciones nuevas). Se persiste por usuario.
class NotificationSettingsView extends StatefulWidget {
  final String userId;
  const NotificationSettingsView({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  Map<String, bool>? _values;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = <String, bool>{};
    for (final type in ['streak', 'upload', 'recommendation']) {
      values[type] = await NotificationSettingsService.isEnabled(widget.userId, type);
    }
    if (mounted) setState(() => _values = values);
  }

  Future<void> _toggle(String type, bool value) async {
    setState(() => _values![type] = value);
    await NotificationSettingsService.setEnabled(widget.userId, type, value);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);

    final types = [
      (type: 'streak', title: t.notifStreak, subtitle: t.notifStreakSub, icon: Icons.local_fire_department_rounded),
      (type: 'upload', title: t.notifUpload, subtitle: t.notifUploadSub, icon: Icons.upload_file_rounded),
      (type: 'recommendation', title: t.notifRecommendation, subtitle: t.notifRecommendationSub, icon: Icons.auto_awesome_rounded),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.notifications)),
      body: _values == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              t.notifChooseText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ...types.map((tp) => _NotificationSwitchTile(
            icon: tp.icon,
            title: tp.title,
            subtitle: tp.subtitle,
            value: _values![tp.type] ?? true,
            onChanged: (v) => _toggle(tp.type, v),
          )),
        ],
      ),
    );
  }
}

class _NotificationSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(icon, color: colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}