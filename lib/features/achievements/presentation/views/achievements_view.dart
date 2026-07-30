import 'package:flutter/material.dart';

import '../../data/services/achievement_service.dart';
import '../components/achievement_card.dart';
import '../components/achievements_summary_card.dart';

/// Pantalla "Logros" -- muestra el catálogo completo (bloqueados y
/// desbloqueados), los puntos totales y el nivel de lector actual.
class AchievementsView extends StatefulWidget {
  final String userId;
  const AchievementsView({super.key, required this.userId});

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
    final unlocked = _unlocked;
    final catalog = AchievementService.catalog;

    return Scaffold(
      appBar: AppBar(title: const Text('Logros')),
      body: unlocked == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          AchievementsSummaryCard(
            points: _points,
            unlockedCount: unlocked.length,
            totalCount: catalog.length,
          ),
          for (final achievement in catalog)
            AchievementCard(
              achievement: achievement,
              isUnlocked: unlocked.contains(achievement.id),
            ),
        ],
      ),
    );
  }
}