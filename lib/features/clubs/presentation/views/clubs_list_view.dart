import 'package:flutter/material.dart';

/// Placeholder temporal de "Club" mientras se fusiona el feature real
/// (rama feat/tutorHibrido, con lista/detalle/chat/crear club de verdad).
///
/// Para reemplazarlo después: borra este archivo y copia el
/// `clubs_list_view.dart` real de esa rama en esta misma ruta — el
/// constructor con `embedded` ya coincide, así que no hay que tocar
/// nada más (ni el CAPTCHA, ni el shell).
class ClubsListView extends StatefulWidget {
  /// Cuando es true, se usa como pestaña dentro de MainTabShell: no
  /// dibuja su propio Scaffold ni barra inferior.
  final bool embedded;

  const ClubsListView({super.key, this.embedded = false});

  @override
  State<ClubsListView> createState() => _ClubsListViewState();
}

class _ClubsListViewState extends State<ClubsListView> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.groups_rounded,
              size: 48, color: colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            'Club — próximamente',
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 4),
          Text(
            '(placeholder temporal — se reemplaza al fusionar el feature real)',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.35)),
          ),
        ],
      ),
    );

    if (widget.embedded) return content;
    return Scaffold(body: content);
  }
}