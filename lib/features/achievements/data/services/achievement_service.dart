import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../notifications/data/services/notification_service.dart';

/// Definición de un logro del catálogo (fijo, no se guarda en disco —
/// solo se guarda qué ids ya desbloqueó el usuario).
class AchievementDef {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int points;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.points,
  });
}

/// Sistema de logros con recompensa en puntos → nivel de lector.
/// Todo persistido localmente por usuario.
class AchievementService {
  static const List<AchievementDef> catalog = [
    AchievementDef(
      id: 'streak_1',
      title: '¡A leer!',
      description: 'Lee un libro por primera vez',
      icon: Icons.menu_book_rounded,
      points: 10,
    ),
    AchievementDef(
      id: 'streak_3',
      title: 'Constancia',
      description: 'Racha de lectura de 3 días',
      icon: Icons.local_fire_department_rounded,
      points: 25,
    ),
    AchievementDef(
      id: 'streak_7',
      title: 'Semana completa',
      description: 'Racha de lectura de 7 días',
      icon: Icons.whatshot_rounded,
      points: 50,
    ),
    AchievementDef(
      id: 'streak_30',
      title: 'Lector imparable',
      description: 'Racha de lectura de 30 días',
      icon: Icons.local_fire_department_rounded,
      points: 200,
    ),
    AchievementDef(
      id: 'book_finished_1',
      title: 'Primera meta',
      description: 'Termina tu primer libro',
      icon: Icons.emoji_events_rounded,
      points: 30,
    ),
    AchievementDef(
      id: 'book_finished_5',
      title: 'Bibliófilo',
      description: 'Termina 5 libros',
      icon: Icons.auto_stories_rounded,
      points: 100,
    ),
    AchievementDef(
      id: 'upload_1',
      title: 'Investigador',
      description: 'Sube tu primer documento para análisis',
      icon: Icons.upload_file_rounded,
      points: 20,
    ),
    AchievementDef(
      id: 'upload_5',
      title: 'Analista experto',
      description: 'Sube 5 documentos para análisis',
      icon: Icons.psychology_rounded,
      points: 80,
    ),
  ];

  static String _key(String userId) => 'achievements_unlocked_$userId';

  static Future<Set<String>> getUnlocked(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(userId)) ?? const []).toSet();
  }

  static Future<int> getTotalPoints(String userId) async {
    final unlocked = await getUnlocked(userId);
    return catalog
        .where((a) => unlocked.contains(a.id))
        .fold<int>(0, (int sum, a) => sum + a.points); // <-- Agregamos <int> y tipamos 'sum'
  }

  /// Nivel de lector según puntos acumulados — la "recompensa" visible
  /// del sistema de logros, se muestra en Perfil.
  static ({String title, int level}) levelFor(int points) {
    if (points >= 300) return (title: 'Maestro lector', level: 5);
    if (points >= 150) return (title: 'Lector experto', level: 4);
    if (points >= 75) return (title: 'Lector dedicado', level: 3);
    if (points >= 25) return (title: 'Lector en crecimiento', level: 2);
    return (title: 'Lector novato', level: 1);
  }

  static Future<void> _unlock(String userId, String achievementId) async {
    final unlocked = await getUnlocked(userId);
    if (unlocked.contains(achievementId)) return; // ya lo tenía

    unlocked.add(achievementId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(userId), unlocked.toList());

    final def = catalog.firstWhere((a) => a.id == achievementId);
    await NotificationService.add(
      userId,
      type: 'achievement',
      title: '¡Logro desbloqueado! 🏆',
      body: '${def.title} — +${def.points} puntos',
      id: 'achievement_${userId}_$achievementId',
    );
  }

  /// Llamar cada vez que se actualiza la racha de lectura.
  static Future<void> checkStreak(String userId, int streakDays) async {
    if (streakDays >= 1) await _unlock(userId, 'streak_1');
    if (streakDays >= 3) await _unlock(userId, 'streak_3');
    if (streakDays >= 7) await _unlock(userId, 'streak_7');
    if (streakDays >= 30) await _unlock(userId, 'streak_30');
  }

  /// Llamar cada vez que un libro llega a >=98% de progreso.
  static Future<void> checkBooksFinished(String userId, int count) async {
    if (count >= 1) await _unlock(userId, 'book_finished_1');
    if (count >= 5) await _unlock(userId, 'book_finished_5');
  }

  /// Llamar cada vez que se sube y analiza un documento con éxito.
  static Future<void> checkUploads(String userId, int count) async {
    if (count >= 1) await _unlock(userId, 'upload_1');
    if (count >= 5) await _unlock(userId, 'upload_5');
  }
}