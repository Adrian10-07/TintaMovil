import '../../../../core/network/http_client.dart';
import '../../domain/entities/recommendation.dart';

class RecommendationRemoteDataSource {
  final ApiClient _apiClient;

  static const String _baseUrl =
      'https://tinta-recommendations.up.railway.app/api/v1/recommendations';

  RecommendationRemoteDataSource(this._apiClient);

  Future<List<Recommendation>> fetchRecommendations() async {
    final data = await _apiClient.get(_baseUrl, auth: true);

    final items = (data is Map && data['items'] is List)
        ? data['items'] as List
        : const [];

    return items
        .map((it) => Recommendation.fromJson(it as Map<String, dynamic>))
        .toList();
  }
}