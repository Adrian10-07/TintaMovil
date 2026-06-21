import '../entities/book.dart';

abstract class BookRepository {
  /// Obtiene una lista de libros basada en una consulta (ej. "programming", "fiction")
  /// e implementa paginación mediante [startIndex] y [maxResults].
  Future<List<Book>> getBooksCatalog({
    required String query,
    required int startIndex,
    required int maxResults,
  });
}