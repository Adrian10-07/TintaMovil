import 'package:flutter/foundation.dart';

import '../../../recommendations/data/datasources/recommendation_remote_datasource.dart';
import '../../../recommendations/domain/entities/recommendation.dart';

/// Encapsula la carga de recomendaciones relacionadas al documento abierto.

class RecommendationsController extends ChangeNotifier {
  final RecommendationRemoteDataSource _dataSource;

  RecommendationsController({required RecommendationRemoteDataSource dataSource})
      : _dataSource = dataSource;

  List<Recommendation>? _items;
  List<Recommendation>? get items => _items;

  String? _error;
  String? get error => _error;

  Future<void> load() async {
    try {
      final result = await _dataSource.fetchRecommendations();
      _items = result;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }
}