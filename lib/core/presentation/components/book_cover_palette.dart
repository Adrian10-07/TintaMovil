import 'package:flutter/material.dart';

/// Genera un gradiente de portada consistente para un libro, basado en
/// un hash determinístico de su [id]. El mismo libro siempre obtiene
/// el mismo gradiente (no cambia entre sesiones ni entre aperturas),
/// pero libros distintos suelen caer en colores distintos.
class BookCoverPalette {
  /// Paleta curada de pares [colorClaro, colorOscuro] para construir
  /// gradientes diagonales atractivos. Elegidos a mano para que
  /// siempre se vean bien en combinación (no se generan colores random
  /// puros, que podrían dar combinaciones feas o ilegibles).
  static const List<List<Color>> _gradients = [
    [Color(0xFFF5C842), Color(0xFFB8860B)], // dorado (igual a la referencia)
    [Color(0xFF6B5FD8), Color(0xFF3D3580)], // morado profundo
    [Color(0xFF1C9E75), Color(0xFF0F6E56)], // verde Tinta
    [Color(0xFFE0654B), Color(0xFF993C1D)], // coral/terracota
    [Color(0xFF378ADD), Color(0xFF0C447C)], // azul
    [Color(0xFFD4537E), Color(0xFF72243E)], // rosa intenso
    [Color(0xFF639922), Color(0xFF27500A)], // verde oliva
    [Color(0xFF7F77DD), Color(0xFF26215C)], // lavanda oscuro
  ];

  /// Devuelve siempre el mismo gradiente para el mismo [bookId].
  static LinearGradient forBookId(String bookId) {
    final index = _hashToIndex(bookId, _gradients.length);
    final colors = _gradients[index];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  /// Devuelve solo el color base (más oscuro) del gradiente, útil para
  /// la barra de estado o acentos sólidos.
  static Color baseColorForBookId(String bookId) {
    final index = _hashToIndex(bookId, _gradients.length);
    return _gradients[index][1];
  }

  /// Hash simple y determinístico (suma de códigos de carácter),
  /// suficiente para distribuir libros entre la paleta sin necesitar
  /// un algoritmo criptográfico — solo buscamos variedad visual estable.
  static int _hashToIndex(String input, int rangeSize) {
    int hash = 0;
    for (final codeUnit in input.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7FFFFFFF;
    }
    return hash % rangeSize;
  }
}