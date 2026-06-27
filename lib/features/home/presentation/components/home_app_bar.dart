import 'package:flutter/material.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';

/// AppBar personalizado de la pantalla Home.
///
/// Muestra avatar con gradiente, saludo contextual y campana de notificaciones.
class HomeAppBar extends StatelessWidget {
  final String greeting;
  final String title;
  final String avatarInitial;
  final bool hasNotifications;
  final VoidCallback? onNotificationTap;

  const HomeAppBar({
    Key? key,
    this.greeting = 'Buenas tardes 👋',
    this.title = 'Catálogo Tinta',
    this.avatarInitial = 'A',
    this.hasNotifications = true,
    this.onNotificationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // ── Avatar + saludo ────────────────────────────────
          _Avatar(initial: avatarInitial),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.50),
                ),
              ),
              Text(title, style: textTheme.titleMedium),
            ],
          ),
          const Spacer(),

          // ── Campana de notificaciones ───────────────────────
          _NotificationBell(
            hasNotifications: hasNotifications,
            onTap: onNotificationTap,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String initial;

  const _Avatar({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: MaterialTheme.avatarGradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final bool hasNotifications;
  final VoidCallback? onTap;

  const _NotificationBell({
    required this.hasNotifications,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_outlined,
              color: colorScheme.onSurface,
              size: 20,
            ),
          ),
          if (hasNotifications)
            Positioned(
              right: 10,
              top: 9,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}