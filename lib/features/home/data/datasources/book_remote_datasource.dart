import '../../../../core/network/http_client.dart';
import '../models/google_book_model.dart';
import '../../domain/entities/book.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BookRemoteDataSource {
  final ApiClient _apiClient;
  final String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  // TODO: Reemplaza esto con la clave que obtuviste en Google Cloud

  BookRemoteDataSource(this._apiClient);

  Future<List<Book>> fetchGoogleBooks({
    required String query,
    required int startIndex,
    required int maxResults,
  }) async {
    final encodedQuery = Uri.encodeComponent(query);

    // SOLUCIÓN: Agregamos el parámetro &key=$_apiKey al final de la URL
    final url =  dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? '';

    try {
      final responseData = await _apiClient.get(url);
      return GoogleBookModel.fromGoogleApiJson(responseData);
    } catch (e) {
      rethrow;
    }
  }
}