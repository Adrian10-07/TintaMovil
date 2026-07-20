import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Snapshot del progreso de un libro para mostrar en "Leyendo actualmente".
class ReadingLibraryEntry {
  final String bookId;
  final String title;
  final String author;
  final int currentPage;
  final int totalPages;
  final DateTime lastReadAt;

  ReadingLibraryEntry({
    required this.bookId,
    required this.title,
    required this.author,
    required this.currentPage,
    required this.totalPages,
    required this.lastReadAt,
  });

  double get progress =>
      totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;

  int get percent => (progress * 100).round();

  Map<String, dynamic> toJson() => {
    'bookId': bookId,
    'title': title,
    'author': author,
    'currentPage': currentPage,
    'totalPages': totalPages,
    'lastReadAt': lastReadAt.toIso8601String(),
  };

  factory ReadingLibraryEntry.fromJson(Map<String, dynamic> json) {
    // Compatibilidad con datos guardados antes de renombrar
    // currentChapter/totalChapters → currentPage/totalPages.
    final currentPage = json['currentPage'] ?? json['currentChapter'] ?? 0;
    final totalPages = json['totalPages'] ?? json['totalChapters'] ?? 0;

    return ReadingLibraryEntry(
      bookId: json['bookId'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      currentPage: currentPage as int,
      totalPages: totalPages as int,
      lastReadAt: DateTime.parse(json['lastReadAt'] as String),
    );
  }
}

/// Guarda localmente qué libros está leyendo el usuario (por capítulo
/// alcanzado) para poder mostrarlos en "Leyendo actualmente" en Home.
///
/// No depende del backend porque hoy no existe un endpoint que liste TODO
/// el progreso de un usuario (solo GET /reading-progress/{bookId} para un
/// libro puntual), así que se arma la lista aquí, en el dispositivo.
class ReadingLibraryService {
  static String _key(String userId) => 'reading_library_$userId';

  /// Actualiza (o crea) la entrada de un libro. Se llama cada vez que el
  /// usuario avanza de capítulo en el lector.
  static Future<void> upsert(String userId, ReadingLibraryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? [];

    final entries = raw
        .map((e) => ReadingLibraryEntry.fromJson(
        json.decode(e) as Map<String, dynamic>))
        .where((e) => e.bookId != entry.bookId)
        .toList()
      ..add(entry);

    await prefs.setStringList(
      _key(userId),
      entries.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  /// Elimina la entrada de un libro específico (borrar de "Leyendo
  /// actualmente" manualmente).
  static Future<void> remove(String userId, String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? [];

    final entries = raw
        .map((e) => ReadingLibraryEntry.fromJson(
        json.decode(e) as Map<String, dynamic>))
        .where((e) => e.bookId != bookId)
        .toList();

    await prefs.setStringList(
      _key(userId),
      entries.map((e) => json.encode(e.toJson())).toList(),
    );
  }

  /// Borra todo el historial de progreso de lectura del usuario (Perfil >
  /// Privacidad > "Borrar historial de lectura").
  static Future<void> clearAll(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }

  /// Todas las entradas guardadas (sin filtrar por progreso), indexadas
  /// por bookId. Se usa para mostrar el % real en las tarjetas del
  /// catálogo, incluyendo libros ya terminados (100%).
  static Future<Map<String, ReadingLibraryEntry>> getAllIndexed(
      String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? [];

    final entries = raw.map((e) => ReadingLibraryEntry.fromJson(
        json.decode(e) as Map<String, dynamic>));

    return {for (final e in entries) e.bookId: e};
  }

  /// Libros con progreso guardado, más reciente primero. Se excluyen los
  /// que ya se terminaron (>=98% avanzado).
  static Future<List<ReadingLibraryEntry>> getInProgress(
      String userId, {
        int limit = 10,
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? [];

    final entries = raw
        .map((e) => ReadingLibraryEntry.fromJson(
        json.decode(e) as Map<String, dynamic>))
        .where((e) => e.progress < 0.98)
        .toList()
      ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));

    return entries.take(limit).toList();
  }
}