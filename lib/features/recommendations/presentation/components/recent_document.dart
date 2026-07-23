import 'package:flutter/material.dart';

/// Representa un documento subido recientemente por el usuario, con su
/// metadata real (páginas, tamaño) leída del archivo por
/// RecentDocumentsService — ya no es un mock.
class RecentDocument {
  final String path;
  final String title;
  final int pages;
  final double sizeMb;
  final DocumentType type;
  final double? progress; // 0.0 - 1.0, null = sin progreso de análisis aún

  const RecentDocument({
    required this.path,
    required this.title,
    required this.pages,
    required this.sizeMb,
    required this.type,
    this.progress,
  });

  String get sizeLabel => '${sizeMb.toStringAsFixed(1)} MB';
}

enum DocumentType { pdf, epub }

/// Color e ícono asociados a cada documento individual, para los chips
/// de la lista de "Recientes" (cada item tiene su propio acento de color).
class DocumentTypeStyle {
  final Color background;
  final Color foreground;
  final String label;

  const DocumentTypeStyle({
    required this.background,
    required this.foreground,
    required this.label,
  });

  /// Asigna un color distinto por índice en la lista, para que cada
  /// tarjeta tenga su propio acento visual (no todas del mismo color).
  static DocumentTypeStyle forIndex(int index, ColorScheme scheme) {
    final palette = [
      const Color(0xFF6B5FD8), // morado
      const Color(0xFFE0654B), // coral
      const Color(0xFF1C6B50), // verde (primary de Tinta)
    ];
    final color = palette[index % palette.length];
    return DocumentTypeStyle(
      background: color,
      foreground: Colors.white,
      label: 'PDF',
    );
  }
}