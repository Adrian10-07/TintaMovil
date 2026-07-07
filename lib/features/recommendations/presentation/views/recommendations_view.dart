import 'package:flutter/material.dart';

import 'package:tinta/core/di/service_locator.dart';
import 'package:tinta/core/network/http_client.dart';

import '../../data/datasources/recommendation_remote_datasource.dart';
import '../../domain/entities/recommendation.dart';

/// Vista de recomendaciones: tarjetas con portada, título, autores,
/// porcentaje de afinidad y el "por qué" de cada recomendación.
class RecommendationsView extends StatefulWidget {
  const RecommendationsView({Key? key}) : super(key: key);

  @override
  State<RecommendationsView> createState() => _RecommendationsViewState();
}

class _RecommendationsViewState extends State<RecommendationsView> {
  // ── Paleta Tinta ──────────────────────────────────────────────
  static const _mintPrimary = Color(0xFF3DBF7A);
  static const _deepGreen = Color(0xFF1A4D2E);
  static const _warmGold = Color(0xFFF5C842);
  static const _peach = Color(0xFFFFBF9B);
  static const _offWhite = Color(0xFFF2F5EF);
  static const _darkText = Color(0xFF1A2B1F);

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
      backgroundColor: _offWhite,
      appBar: AppBar(
        backgroundColor: _offWhite,
        elevation: 0,
        foregroundColor: _deepGreen,
        title: Text(
          'Te puede interesar',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w800,
            color: _deepGreen,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _StateMessage(
        icon: Icons.wifi_off_rounded,
        iconColor: _peach,
        title: 'No se pudo cargar',
        message: _error!,
        darkText: _darkText,
        action: TextButton.icon(
          onPressed: _load,
          icon: Icon(Icons.refresh_rounded, color: _mintPrimary),
          label: Text('Reintentar',
              style: TextStyle(
                  color: _mintPrimary, fontWeight: FontWeight.w700)),
        ),
      );
    }
    if (_items == null) {
      return Center(
        child: CircularProgressIndicator(color: _mintPrimary),
      );
    }
    if (_items!.isEmpty) {
      return _StateMessage(
        icon: Icons.auto_stories_outlined,
        iconColor: _mintPrimary,
        title: 'Aún no hay recomendaciones',
        message: 'Sube un libro desde el inicio para recibir '
            'recomendaciones basadas en su contenido.',
        darkText: _darkText,
      );
    }

    return RefreshIndicator(
      color: _mintPrimary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final r = _items![i];
          return _RecommendationCard(
            recommendation: r,
            mintPrimary: _mintPrimary,
            deepGreen: _deepGreen,
            warmGold: _warmGold,
            peach: _peach,
            darkText: _darkText,
          );
        },
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final Color mintPrimary;
  final Color deepGreen;
  final Color warmGold;
  final Color peach;
  final Color darkText;

  const _RecommendationCard({
    required this.recommendation,
    required this.mintPrimary,
    required this.deepGreen,
    required this.warmGold,
    required this.peach,
    required this.darkText,
  });

  Color get _matchColor {
    final p = recommendation.matchPercent;
    if (p >= 70) return mintPrimary;
    if (p >= 40) return warmGold;
    return peach;
  }

  @override
  Widget build(BuildContext context) {
    final r = recommendation;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: darkText.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Portada ──────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 80,
              child: r.thumbnailUrl != null
                  ? Image.network(
                r.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _CoverPlaceholder(
                  color: mintPrimary,
                ),
              )
                  : _CoverPlaceholder(color: mintPrimary),
            ),
          ),
          const SizedBox(width: 14),

          // ── Info ─────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        r.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: deepGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MatchBadge(percent: r.matchPercent, color: _matchColor),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  r.authors.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12.5,
                    color: darkText.withOpacity(0.55),
                  ),
                ),
                if (r.matchReason != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: mintPrimary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r.matchReason!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: deepGreen,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  final int percent;
  final Color color;

  const _MatchBadge({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final Color color;
  const _CoverPlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withOpacity(0.15),
      child: Icon(Icons.menu_book_rounded, color: color, size: 24),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Color darkText;
  final Widget? action;

  const _StateMessage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.darkText,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                color: darkText.withOpacity(0.55),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}