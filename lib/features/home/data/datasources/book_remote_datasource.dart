import '../../../../core/network/http_client.dart';
import '../models/google_book_model.dart';
import '../../domain/entities/book.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BookRemoteDataSource {
  final ApiClient _apiClient;
  final String _baseUrl = 'https://www.googleapis.com/books/v1/volumes';

  BookRemoteDataSource(this._apiClient);

  Future<List<Book>> fetchGoogleBooks({
    required String query,
    required int startIndex,
    required int maxResults,
  }) async {
    final encodedQuery = Uri.encodeComponent(query);

    // 1. Obtenemos la clave de forma segura del .env
    final apiKey = dotenv.env['GOOGLE_BOOKS_API_KEY'] ?? '';

    // 2. Armamos la URL completa sumando la ruta, los parámetros y la clave al final
    final url = '$_baseUrl?q=$encodedQuery&startIndex=$startIndex&maxResults=$maxResults&key=$apiKey';

    try {
      final responseData = await _apiClient.get(url);
      return GoogleBookModel.fromGoogleApiJson(responseData);
    } catch (e) {
      rethrow;
    }
  }
}