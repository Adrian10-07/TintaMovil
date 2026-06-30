import '../entities/book.dart';

abstract class BookRepository {
  Future<List<Book>> getBooksCatalog({String? category});
}