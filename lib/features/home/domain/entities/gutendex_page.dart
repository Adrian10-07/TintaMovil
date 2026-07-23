import 'book.dart';

/// Una página de resultados al pedir más libros para el scroll infinito
/// del catálogo (actualmente desde Gutendex/Project Gutenberg).
class GutendexPage {
  final List<Book> books;
  final String? nextPageUrl;

  const GutendexPage({required this.books, required this.nextPageUrl});
}