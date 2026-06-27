import '../../domain/entities/book.dart';

class GoogleBookModel {
  static List<Book> fromGoogleApiJson(Map<String, dynamic> json) {
    if (json['items'] == null) return [];

    final List<dynamic> items = json['items'];
    return items.map((item) {
      final volumeInfo = item['volumeInfo'] ?? {};
      final imageLinks = volumeInfo['imageLinks'] ?? {};
      final accessInfo = item['accessInfo'] ?? {};

      return Book(
        id: item['id'] ?? '',
        title: volumeInfo['title'] ?? 'Sin título',
        authors: List<String>.from(
          volumeInfo['authors'] ?? ['Autor desconocido'],
        ),
        description: volumeInfo['description'],
        thumbnailUrl: imageLinks['thumbnail']
            ?.toString()
            .replaceAll('http://', 'https://'),
        previewLink: volumeInfo['previewLink'],
        pageCount: volumeInfo['pageCount'] ?? 0,

        // ── Access info para lectura in-app ─────────────────
        webReaderLink: accessInfo['webReaderLink'],
        viewability: accessInfo['viewability'] ?? 'UNKNOWN',
        embeddable: accessInfo['embeddable'] ?? false,
      );
    }).toList();
  }
}