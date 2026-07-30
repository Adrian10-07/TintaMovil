import 'package:flutter/material.dart';

import '../../domain/achievement_catalog.dart';

/// Tarjeta de resumen: nivel actual del lector + puntos totales.
class AchievementsSummaryCard extends StatelessWidget {
  final int points;
  final int unlockedCount;
  final int totalCount;

  const AchievementsSummaryCard({
    super.key,
    required this.points,
    required this.unlockedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final level = AchievementCatalog.levelFor(points);

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.military_tech_rounded, color: cs.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.title,
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '$points puntos · $unlockedCount de $totalCount logros',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withOpacity(0.6),
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