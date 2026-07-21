import '../../domain/entities/book.dart';

class CuratedBookModel {
  static List<Book> fromCatalogJson(Map<String, dynamic> json) {
    final List<dynamic> books = json['books'] ?? [];

    return books.map((item) {
      final String pageUrl = item['pageUrl'] ?? '';

      // Standard Ebooks publica la portada de cada libro en una URL
      // predecible y estable: {pageUrl}/downloads/cover.jpg (confirmado
      // como el og:image real de sus páginas). Si el catálogo curado no
      // trae thumbnailUrl explícito, la derivamos de ahí en vez de dejar
      // la portada vacía.
      final String? thumbnailFromJson = item['thumbnailUrl'];
      final String? derivedThumbnail = pageUrl.isNotEmpty
          ? '$pageUrl/downloads/cover.jpg'
          : null;

      return Book(
        id: item['id'] ?? '',
        title: item['title'] ?? 'Sin título',
        authors: List<String>.from(item['authors'] ?? ['Autor desconocido']),
        description: item['description'],
        thumbnailUrl: thumbnailFromJson ?? derivedThumbnail,
        category: item['category'] ?? 'General',
        subjects: List<String>.from(item['subjects'] ?? []),
        epubUrl: item['epubUrl'] ?? '',
        pageUrl: pageUrl,
      );
    }).toList();
  }
}