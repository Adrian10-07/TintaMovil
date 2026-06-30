import 'package:flutter/material.dart';

/// Representa un documento subido recientemente por el usuario.
/// Por ahora se llena con datos de ejemplo (mock); cuando exista
/// persistencia real, este modelo se alimenta desde el backend.
class RecentDocument {
  final String title;
  final int pages;
  final double sizeMb;
  final DocumentType type;
  final double? progress; // 0.0 - 1.0, null = sin progreso de estudio aún

  const RecentDocument({
    required this.title,
    required this.pages,
    required this.sizeMb,
    required this.type,
    this.progress,
  });

  String get sizeLabel => '${sizeMb.toStringAsFixed(1)} MB';
}

enum DocumentType { pdf, epub }

/// Datos de ejemplo — reemplazar por la fuente real (backend/local db)
/// cuando exista persistencia de documentos subidos.
const List<RecentDocument> mockRecentDocuments = [
  RecentDocument(
    title: 'Apuntes Termodinámica',
    pages: 42,
    sizeMb: 2.4,
    type: DocumentType.pdf,
  ),
  RecentDocument(
    title: 'Anatomía Sistema Óseo',
    pages: 87,
    sizeMb: 5.1,
    type: DocumentType.pdf,
  ),
  RecentDocument(
    title: 'Cálculo Vectorial Laplace',
    pages: 16,
    sizeMb: 1.2,
    type: DocumentType.pdf,
    progress: 0.52,
  ),
];

/// Color e ícono asociados a cada tipo de documento, para los chips
/// de la lista de "Recientes".


/// Color e ícono asociados a cada documento individual, para los chips
/// de la lista de "Recientes" (cada item tiene su propio acento de color,
/// igual que en la imagen de referencia).
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
