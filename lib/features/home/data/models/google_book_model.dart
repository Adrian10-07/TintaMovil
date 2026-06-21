import '../../domain/entities/book.dart';

class GoogleBookModel {
  static List<Book> fromGoogleApiJson(Map<String, dynamic> json) {
    if (json['items'] == null) return [];

    final List<dynamic> items = json['items'];
    return items.map((item) {
      final volumeInfo = item['volumeInfo'] ?? {};
      final imageLinks = volumeInfo['imageLinks'] ?? {};

      return Book(
        id: item['id'] ?? '',
        title: volumeInfo['title'] ?? 'Sin título',
        authors: List<String>.from(volumeInfo['authors'] ?? ['Autor desconocido']),
        description: volumeInfo['description'],
        // Reemplazamos http por https para evitar problemas de seguridad en iOS/Android
        thumbnailUrl: imageLinks['thumbnail']?.toString().replaceAll('http://', 'https://'),
        previewLink: volumeInfo['previewLink'],
      );
    }).toList();
  }
}