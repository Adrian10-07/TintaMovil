import 'package:flutter/material.dart';

import 'entities/achievement_def.dart';

/// Catálogo fijo de logros disponibles en la app y la regla de niveles.

abstract final class AchievementCatalog {
  static const List<AchievementDef> all = [
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

  static AchievementDef byId(String id) => all.firstWhere((a) => a.id == id);

  /// Nivel de lector según puntos acumulados — la "recompensa" visible del
  /// sistema de logros, se muestra en Perfil.
  static ReaderLevel levelFor(int points) {
    if (points >= 300) return const ReaderLevel(title: 'Maestro lector', level: 5);
    if (points >= 150) return const ReaderLevel(title: 'Lector experto', level: 4);
    if (points >= 75) return const ReaderLevel(title: 'Lector dedicado', level: 3);
    if (points >= 25) return const ReaderLevel(title: 'Lector en crecimiento', level: 2);
    return const ReaderLevel(title: 'Lector novato', level: 1);
  }
}