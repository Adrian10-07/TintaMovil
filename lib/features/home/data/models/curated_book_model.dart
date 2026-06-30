import '../../domain/entities/book.dart';

class CuratedBookModel {
  static List<Book> fromCatalogJson(Map<String, dynamic> json) {
    final List<dynamic> books = json['books'] ?? [];

    return books.map((item) {
      return Book(
        id: item['id'] ?? '',
        title: item['title'] ?? 'Sin título',
        authors: List<String>.from(item['authors'] ?? ['Autor desconocido']),
        description: item['description'],
        thumbnailUrl: item['thumbnailUrl'],
        category: item['category'] ?? 'General',
        subjects: List<String>.from(item['subjects'] ?? []),
        epubUrl: item['epubUrl'] ?? '',
        pageUrl: item['pageUrl'] ?? '',
      );
    }).toList();
  }
}