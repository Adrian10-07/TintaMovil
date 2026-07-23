import 'package:flutter/material.dart';
import '../../data/services/achievement_service.dart';

/// Pantalla "Logros" — muestra el catálogo completo (bloqueados y
/// desbloqueados), los puntos totales y el nivel de lector actual.
class AchievementsView extends StatefulWidget {
  final String userId;
  const AchievementsView({Key? key, required this.userId}) : super(key: key);

  @override
  State<AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<AchievementsView> {
  Set<String>? _unlocked;
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final unlocked = await AchievementService.getUnlocked(widget.userId);
    final points = await AchievementService.getTotalPoints(widget.userId);
    if (mounted) {
      setState(() {
        _unlocked = unlocked;
        _points = points;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final unlocked = _unlocked;

    return Scaffold(
      appBar: AppBar(title: const Text('Logros')),
      body: unlocked == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        children: [
          // ── Resumen: puntos + nivel actual ──────────────────
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.military_tech_rounded, color: colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AchievementService.levelFor(_points).title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Text(
                        '$_points puntos · ${unlocked.length} de ${AchievementService.catalog.length} logros',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Catálogo completo ────────────────────────────────
          ...AchievementService.catalog.map((a) {
            final isUnlocked = unlocked.contains(a.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: isUnlocked
                    ? Border.all(color: colorScheme.primary.withOpacity(0.4))
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? colorScheme.primaryContainer
                          : colorScheme.onSurface.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUnlocked ? a.icon : Icons.lock_outline_rounded,
                      color: isUnlocked
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.35),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isUnlocked ? null : colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        Text(
                          a.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(isUnlocked ? 0.6 : 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? colorScheme.primary.withOpacity(0.15)
                          : colorScheme.onSurface.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '+${a.points}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isUnlocked
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}