import 'package:flutter/material.dart';

/// Definición de un logro del catálogo.

@immutable
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

/// Nivel de lector calculado a partir de los puntos acumulados.
@immutable
class ReaderLevel {
  final String title;
  final int level;

  const ReaderLevel({required this.title, required this.level});
}