import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_remote_datasource.dart';

class BookRepositoryImpl implements BookRepository {
  final BookRemoteDataSource remoteDataSource;

  BookRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Book>> getBooksCatalog({
    required String query,
    required int startIndex,
    required int maxResults,
  }) async {
    try {
      return await remoteDataSource.fetchGoogleBooks(
        query: query,
        startIndex: startIndex,
        maxResults: maxResults,
      );
    } catch (e) {
      // Manejo y tipado de errores de infraestructura a nivel de dominio
      rethrow;
    }
  }
}