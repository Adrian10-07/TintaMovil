import 'package:flutter/material.dart';
import '../../../notifications/data/services/notification_settings_service.dart';

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
  static const _types = [
    (
    type: 'streak',
    title: 'Racha de lectura',
    subtitle: 'Cuando subes de racha al abrir la app cada día.',
    icon: Icons.local_fire_department_rounded,
    ),
    (
    type: 'upload',
    title: 'Documentos subidos',
    subtitle: 'Cuando terminas de subir y analizar un PDF.',
    icon: Icons.upload_file_rounded,
    ),
    (
    type: 'recommendation',
    title: 'Recomendaciones nuevas',
    subtitle: 'Cuando el motor ML encuentra libros para ti.',
    icon: Icons.auto_awesome_rounded,
    ),
  ];

  Map<String, bool>? _values;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final values = <String, bool>{};
    for (final t in _types) {
      values[t.type] = await NotificationSettingsService.isEnabled(widget.userId, t.type);
    }
    if (mounted) setState(() => _values = values);
  }

  Future<void> _toggle(String type, bool value) async {
    setState(() => _values![type] = value);
    await NotificationSettingsService.setEnabled(widget.userId, type, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: _values == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'Elige qué te queremos avisar dentro de la app.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          ..._types.map((t) => _NotificationSwitchTile(
            icon: t.icon,
            title: t.title,
            subtitle: t.subtitle,
            value: _values![t.type] ?? true,
            onChanged: (v) => _toggle(t.type, v),
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