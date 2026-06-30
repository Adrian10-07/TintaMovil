
import 'package:flutter/material.dart';

/// Representa un libro que el usuario está leyendo actualmente,
/// con su progreso. Por ahora con datos mock — cuando exista
/// tracking real de lectura, este modelo se alimenta del backend.
class CurrentlyReadingBook {
  final String title;
  final String author;
  final int totalPages;
  final double progress; // 0.0 - 1.0
  final IconData icon;
  final Color accentColor;

  const CurrentlyReadingBook({
    required this.title,
    required this.author,
    required this.totalPages,
    required this.progress,
    required this.icon,
    required this.accentColor,
  });

  int get percent => (progress * 100).round();
}

/// Datos de ejemplo — reemplazar por la fuente real (backend) cuando
/// exista persistencia de progreso de lectura.
const List<CurrentlyReadingBook> mockCurrentlyReading = [
  CurrentlyReadingBook(
    title: 'Atomic Habits',
    author: 'J. Clear',
    totalPages: 320,
    progress: 0.68,
    icon: Icons.bolt_rounded,
    accentColor: Color(0xFF1C6B50),
  ),
  CurrentlyReadingBook(
    title: 'Midnight Library',
    author: 'M. Haig',
    totalPages: 288,
    progress: 0.32,
    icon: Icons.nightlight_round,
    accentColor: Color(0xFF6B5FD8),
  ),
];