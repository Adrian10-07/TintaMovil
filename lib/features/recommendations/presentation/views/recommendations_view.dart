import 'package:flutter/material.dart';

import 'package:tinta/core/di/service_locator.dart';
import 'package:tinta/core/network/http_client.dart';

import '../../data/datasources/recommendation_remote_datasource.dart';
import '../../domain/entities/recommendation.dart';

/// Vista mínima: solo texto con los libros recomendados. Sin tarjetas,
/// sin imágenes, sin estilos especiales — lista simple para mostrar rápido.
class RecommendationsView extends StatefulWidget {
  const RecommendationsView({Key? key}) : super(key: key);

  @override
  State<RecommendationsView> createState() => _RecommendationsViewState();
}

class _RecommendationsViewState extends State<RecommendationsView> {
  final _dataSource = RecommendationRemoteDataSource(sl<ApiClient>());

  List<Recommendation>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _items = null;
      _error = null;
    });
    try {
      final result = await _dataSource.fetchRecommendations();
      setState(() => _items = result);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Te puede interesar')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }
    if (_items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items!.isEmpty) {
      return const Center(child: Text('Aún no hay recomendaciones.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items!.length,
      itemBuilder: (_, i) {
        final r = _items![i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '${r.title} — ${r.authors.join(', ')}',
            style: const TextStyle(fontSize: 16),
          ),
        );
      },
    );
  }
}