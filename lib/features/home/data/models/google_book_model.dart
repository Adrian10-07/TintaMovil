import '../../domain/entities/book.dart';
import '../../domain/entities/gutendex_page.dart';

/// Parsea la respuesta de la API pública de Gutendex
/// (https://gutendex.com/books/), un espejo JSON gratuito y sin API key
/// del catálogo de Project Gutenberg (70,000+ libros).
///
/// Se usa para "extender" el catálogo curado: cuando el usuario llega al
/// final de la lista, se piden más libros de aquí en vez de limitarse a
/// los que curamos a mano en curated_catalog.json.
class GutendexBookModel {
  /// [json] es la respuesta completa de la API:
  /// { "count": N, "next": "...", "previous": "...", "results": [...] }
  static GutendexPage parsePage(Map<String, dynamic> json) {
    final List<dynamic> results = json['results'] ?? [];

    final books = results
        .map(_parseBook)
        .whereType<Book>() // descarta libros sin EPUB descargable
        .toList();

    return GutendexPage(
      books: books,
      nextPageUrl: json['next'] as String?,
    );
  }

  static Book? _parseBook(dynamic item) {
    final Map<String, dynamic> formats =
    Map<String, dynamic>.from(item['formats'] ?? {});

    final String? epubUrl = _findFormat(formats, 'application/epub+zip');
    if (epubUrl == null) {
      // Sin EPUB descargable, no lo podemos abrir en nuestro lector.
      return null;
    }

    final int id = (item['id'] as num).toInt();

    final List<dynamic> authorsJson = item['authors'] ?? [];
    final authors = authorsJson
        .map((a) => (a is Map ? a['name'] as String? : null) ?? 'Autor desconocido')
        .toList();

    final List<dynamic> subjectsJson = item['subjects'] ?? [];
    final List<dynamic> summariesJson = item['summaries'] ?? [];

    return Book(
      id: 'gutendex_$id',
      title: (item['title'] as String?) ?? 'Sin título',
      authors: authors.isNotEmpty ? authors.cast<String>() : ['Autor desconocido'],
      description: summariesJson.isNotEmpty ? summariesJson.first as String? : null,
      thumbnailUrl: _findFormat(formats, 'image/jpeg'),
      // Categoría propia para poder distinguirlos de los curados a mano
      // en la UI si hace falta, y porque no encajan en las categorías
      // curadas (Estudio, Ciencia, Filosofía, Lectura).
      category: 'Gutenberg',
      subjects: subjectsJson.map((s) => s.toString()).take(5).toList(),
      epubUrl: epubUrl,
      pageUrl: 'https://www.gutenberg.org/ebooks/$id',
    );
  }

  static String? _findFormat(Map<String, dynamic> formats, String mimePrefix) {
    for (final entry in formats.entries) {
      if (entry.key.toString().startsWith(mimePrefix)) {
        return entry.value as String;
      }
    }
    return null;
  }
}