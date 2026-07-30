import 'package:flutter/material.dart';

import '../../domain/entities/achievement_def.dart';

/// Una fila del catálogo de logros: ícono, título, descripción y puntos.

class AchievementCard extends StatelessWidget {
  final AchievementDef achievement;
  final bool isUnlocked;

  const AchievementCard({
    super.key,
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked
            ? Border.all(color: cs.primary.withOpacity(0.4))
            : null,
      ),
      child: Row(
        children: [
          _Badge(icon: achievement.icon, isUnlocked: isUnlocked),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isUnlocked ? null : cs.onSurface.withOpacity(0.5),
                  ),
                ),
                Text(
                  achievement.description,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(isUnlocked ? 0.6 : 0.4),
                  ),
                ),
              ],
            ),
          ),
          _PointsChip(points: achievement.points, isUnlocked: isUnlocked),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final bool isUnlocked;
  const _Badge({required this.icon, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isUnlocked ? cs.primaryContainer : cs.onSurface.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isUnlocked ? icon : Icons.lock_outline_rounded,
        color: isUnlocked ? cs.primary : cs.onSurface.withOpacity(0.35),
        size: 22,
      ),
    );
  }
}

class _PointsChip extends StatelessWidget {
  final int points;
  final bool isUnlocked;
  const _PointsChip({required this.points, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUnlocked
            ? cs.primary.withOpacity(0.15)
            : cs.onSurface.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '+$points',
        style: tt.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: isUnlocked ? cs.primary : cs.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }
}