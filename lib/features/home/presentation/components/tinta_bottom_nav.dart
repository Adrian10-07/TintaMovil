import 'package:flutter/material.dart';
import '../../../../core/localization/app_strings.dart';

/// Barra de navegación inferior con 5 tabs Tinta.
///
/// Tabs: Home, Explorar, Estudio, Club, Yo (traducidos según el idioma
/// elegido en Perfil > Editar perfil).
///
/// [clubBadgeCount] muestra un badge con la cantidad de clubes con mensajes
/// no leídos sobre el icono de Club.
class TintaBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int clubBadgeCount;

  const TintaBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.clubBadgeCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final t = AppStrings.of(context);

    final items = [
      (icon: Icons.home_rounded, label: t.navHome),
      (icon: Icons.explore_rounded, label: t.navExplore),
      (icon: Icons.psychology_rounded, label: t.navStudy),
      (icon: Icons.groups_rounded, label: t.navClub),
      (icon: Icons.person_rounded, label: t.navMe),
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = currentIndex == i;
              final showBadge = i == 3 && clubBadgeCount > 0;

              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge(
                        isLabelVisible: showBadge,
                        label: Text('$clubBadgeCount'),
                        child: Icon(
                          items[i].icon,
                          size: 22,
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].label,
                        style: textTheme.labelSmall?.copyWith(
                          color: selected
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}