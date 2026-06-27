import '../../../../core/network/http_client.dart';
import '../../domain/entities/reading_progress.dart';
import '../models/reading_progress_model.dart';

class ReaderRemoteDataSource {
  final ApiClient _apiClient;

  static const String _baseUrl =
      'https://tintaapi-production-identity.up.railway.app/api/v1';

  ReaderRemoteDataSource(this._apiClient);

  Future<void> saveProgress(ReadingProgress progress) async {
    await _apiClient.post(
      '$_baseUrl/reading-progress',
      body: ReadingProgressModel.toJson(progress),
      auth: true,
    );
  }

  Future<ReadingProgress?> getProgress(String bookId) async {
    try {
      final data = await _apiClient.get(
        '$_baseUrl/reading-progress/$bookId',
        auth: true,
      );
      if (data != null) {
        return ReadingProgressModel.fromJson(data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // Retornar null si falla (ej. progreso no encontrado) para no interrumpir 
      // la inicialización del lector.
      return null;
    }
  }
}
