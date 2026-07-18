import '../entities/book.dart';
import '../entities/gutendex_page.dart';

abstract class BookRepository {
  Future<List<Book>> getBooksCatalog({String? category});

  /// Trae más libros (desde Gutendex) para el scroll infinito del
  /// catálogo. [pageUrl] es la URL de "siguiente página" devuelta por la
  /// llamada anterior; null pide la primera página.
  Future<GutendexPage> fetchMoreBooks({String? pageUrl});

  /// Busca libros por título/autor en Gutendex (para encontrar un EPUB
  /// legible de un libro recomendado que no está en nuestro catálogo).
  Future<GutendexPage> searchBooks(String query);
}