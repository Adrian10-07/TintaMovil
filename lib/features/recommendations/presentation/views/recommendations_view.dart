import 'package:flutter/material.dart';

import 'package:tinta/core/di/service_locator.dart';
import 'package:tinta/core/network/http_client.dart';

import '../../data/datasources/recommendation_remote_datasource.dart';
import '../../domain/entities/recommendation.dart';
import 'recommendation_web_view.dart';
import '../../../home/domain/repositories/book_repository.dart';
import '../../../home/domain/entities/book.dart';

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
  final _bookRepository = sl<BookRepository>();

  bool _searchingFor;
  String? _searchingTitle;

  List<Recommendation>? _items;
  String? _error;

  _RecommendationsViewState() : _searchingFor = false;

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

  /// Al tocar una recomendación: primero intenta encontrar un EPUB real
  /// de ese libro en Gutendex (Project Gutenberg) buscando por título y
  /// autor, y si lo encuentra abre el lector de la app directamente. Solo
  /// si no hay ningún EPUB disponible, cae al link externo o al panel de
  /// descripción como respaldo.
  Future<void> _onRecommendationTap(Recommendation r) async {
    setState(() {
      _searchingFor = true;
      _searchingTitle = r.title;
    });

    Book? found;
    try {
      final query = r.authors.isNotEmpty ? '${r.title} ${r.authors.first}' : r.title;
      final page = await _bookRepository.searchBooks(query);
      found = _bestMatch(page.books, r);
    } catch (_) {
      found = null;
    } finally {
      if (mounted) setState(() => _searchingFor = false);
    }

    if (!mounted) return;

    if (found != null) {
      Navigator.pushNamed(context, '/reader', arguments: found);
      return;
    }

    // No hay EPUB legible de este libro en Gutendex — respaldo.
    if (r.infoLink != null && r.infoLink!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecommendationWebView(url: r.infoLink!, title: r.title),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RecommendationDetailSheet(
        recommendation: r,
        mintPrimary: _mintPrimary,
        deepGreen: _deepGreen,
        darkText: _darkText,
      ),
    );
  }

  /// De los resultados de búsqueda, elige el que más se parece al título
  /// de la recomendación (coincidencia simple por texto, insensible a
  /// mayúsculas). Si ninguno se parece razonablemente, regresa null en
  /// vez de abrir un libro equivocado.
  Book? _bestMatch(List<Book> candidates, Recommendation r) {
    if (candidates.isEmpty) return null;

    final targetTitle = r.title.toLowerCase().trim();
    for (final b in candidates) {
      final candidateTitle = b.title.toLowerCase().trim();
      if (candidateTitle == targetTitle ||
          candidateTitle.contains(targetTitle) ||
          targetTitle.contains(candidateTitle)) {
        return b;
      }
    }
    // Ninguno coincide de forma confiable con el título — mejor no
    // abrir un libro que probablemente no sea el correcto.
    return null;
  }

  void _showAffinityInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Qué es la afinidad?'),
        content: const Text(
          'Es qué tan parecido es este libro al contenido de los documentos '
              'que has subido y analizado. Lo calcula nuestro motor de '
              'recomendaciones comparando temas y palabras clave — mientras '
              'más alto el porcentaje, más se relaciona con lo que ya leíste '
              'o estudiaste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: '¿Qué es la afinidad?',
            onPressed: _showAffinityInfo,
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (_searchingFor)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: _mintPrimary),
                      const SizedBox(height: 12),
                      Text(
                        'Buscando "${_searchingTitle ?? ''}"…',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          color: _darkText.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
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
        itemCount: _items!.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _AffinityExplainer(
              mintPrimary: _mintPrimary,
              deepGreen: _deepGreen,
              onTap: _showAffinityInfo,
            );
          }
          final r = _items![i - 1];
          return _RecommendationCard(
            recommendation: r,
            mintPrimary: _mintPrimary,
            deepGreen: _deepGreen,
            warmGold: _warmGold,
            peach: _peach,
            darkText: _darkText,
            onTap: () => _onRecommendationTap(r),
          );
        },
      ),
    );
  }
}

/// Franja pequeña que explica de una vez qué significa el % en las
/// tarjetas de abajo, para no depender de que el usuario descubra el
/// ícono de info en el AppBar.
class _AffinityExplainer extends StatelessWidget {
  final Color mintPrimary;
  final Color deepGreen;
  final VoidCallback onTap;

  const _AffinityExplainer({
    required this.mintPrimary,
    required this.deepGreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mintPrimary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: mintPrimary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'El % indica qué tan afín es cada libro a lo que ya leíste. Toca uno para ver más.',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11.5,
                  color: deepGreen,
                ),
              ),
            ),
          ],
        ),
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
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.recommendation,
    required this.mintPrimary,
    required this.deepGreen,
    required this.warmGold,
    required this.peach,
    required this.darkText,
    required this.onTap,
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.chevron_right_rounded,
                          size: 14, color: darkText.withOpacity(0.35)),
                      Text(
                        'Toca para ver más',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 10.5,
                          color: darkText.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Panel que se muestra cuando la recomendación no trae un link externo
/// al que navegar — da al menos la descripción y el motivo del match.
class _RecommendationDetailSheet extends StatelessWidget {
  final Recommendation recommendation;
  final Color mintPrimary;
  final Color deepGreen;
  final Color darkText;

  const _RecommendationDetailSheet({
    required this.recommendation,
    required this.mintPrimary,
    required this.deepGreen,
    required this.darkText,
  });

  @override
  Widget build(BuildContext context) {
    final r = recommendation;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 80,
                  child: r.thumbnailUrl != null
                      ? Image.network(r.thumbnailUrl!, fit: BoxFit.cover)
                      : _CoverPlaceholder(color: mintPrimary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title,
                        style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: deepGreen)),
                    const SizedBox(height: 4),
                    Text(r.authors.join(', '),
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 13,
                            color: darkText.withOpacity(0.6))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (r.description != null && r.description!.isNotEmpty)
            Text(
              r.description!,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13.5,
                height: 1.5,
                color: darkText.withOpacity(0.75),
              ),
            )
          else
            Text(
              'No hay más información disponible para este libro por ahora.',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13.5,
                color: darkText.withOpacity(0.5),
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