import '../../domain/entities/book.dart';
import '../../domain/entities/gutendex_page.dart';
import '../../domain/repositories/book_repository.dart';
import '../datasources/book_remote_datasource.dart';

class BookRepositoryImpl implements BookRepository {
  final BookRemoteDataSource remoteDataSource;

  BookRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Book>> getBooksCatalog({String? category}) async {
    return await remoteDataSource.fetchCatalog(category: category);
  }

  @override
  Future<GutendexPage> fetchMoreBooks({String? pageUrl}) async {
    return await remoteDataSource.fetchMoreBooks(pageUrl: pageUrl);
  }
}