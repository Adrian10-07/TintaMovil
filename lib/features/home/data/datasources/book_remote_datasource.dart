import '../../../../core/network/http_client.dart';
import '../models/google_book_model.dart';
import '../../domain/entities/book.dart';

class BookRemoteDataSource {
  final ApiClient _apiClient;
  final String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  // TODO: Reemplaza esto con la clave que obtuviste en Google Cloud
  final String _apiKey='AIzaSyBjf_aDgWubhgX9S0KKLq0xoyUoZBZo7uU';

  BookRemoteDataSource(this._apiClient);

  Future<List<Book>> fetchGoogleBooks({
    required String query,
    required int startIndex,
    required int maxResults,
  }) async {
    final encodedQuery = Uri.encodeComponent(query);

    // SOLUCIÓN: Agregamos el parámetro &key=$_apiKey al final de la URL
    final url = '$_baseUrl?q=$encodedQuery&startIndex=$startIndex&maxResults=$maxResults&key=$_apiKey';

    try {
      final responseData = await _apiClient.get(url);
      return GoogleBookModel.fromGoogleApiJson(responseData);
    } catch (e) {
      rethrow;
    }
  }
}