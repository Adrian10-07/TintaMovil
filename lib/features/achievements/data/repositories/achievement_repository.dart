import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/achievement_catalog.dart';

/// Persistencia de qué logros ya desbloqueó cada usuario.

class AchievementRepository {
  String _key(String userId) => 'achievements_unlocked_$userId';

  Future<Set<String>> getUnlocked(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(userId)) ?? const []).toSet();
  }

  Future<int> getTotalPoints(String userId) async {
    final unlocked = await getUnlocked(userId);
    return AchievementCatalog.all
        .where((a) => unlocked.contains(a.id))
        .fold<int>(0, (sum, a) => sum + a.points);
  }

  /// Marca un logro como desbloqueado.
  Future<bool> unlock(String userId, String achievementId) async {
    final unlocked = await getUnlocked(userId);
    if (unlocked.contains(achievementId)) return false;

    unlocked.add(achievementId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(userId), unlocked.toList());
    return true;
  }
}