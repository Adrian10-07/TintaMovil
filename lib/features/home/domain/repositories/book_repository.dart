import '../entities/book.dart';
import '../entities/gutendex_page.dart';

abstract class BookRepository {
  Future<List<Book>> getBooksCatalog({String? category});

  /// Trae más libros (desde Gutendex) para el scroll infinito del
  /// catálogo. [pageUrl] es la URL de "siguiente página" devuelta por la
  /// llamada anterior; null pide la primera página.
  Future<GutendexPage> fetchMoreBooks({String? pageUrl});
}