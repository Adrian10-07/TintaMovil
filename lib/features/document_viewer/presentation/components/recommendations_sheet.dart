import 'package:flutter/material.dart';

import '../../../recommendations/domain/entities/recommendation.dart';

/// Contenido del bottom sheet "Te puede interesar", mostrado desde el FAB
/// de `PdfResultsView`.

class RecommendationsSheet extends StatelessWidget {
  final List<Recommendation>? items;
  final String? error;
  final ScrollController scrollController;

  const RecommendationsSheet({
    super.key,
    required this.items,
    required this.error,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Te puede interesar',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.primary,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _Body(items: items, error: error, scrollController: scrollController)),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final List<Recommendation>? items;
  final String? error;
  final ScrollController scrollController;

  const _Body({required this.items, required this.error, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: $error',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    if (items == null) {
      return Center(child: CircularProgressIndicator(color: cs.primary));
    }
    if (items!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                color: cs.primary.withOpacity(0.6),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'No encontramos recomendaciones para este libro.\n'
                    'Prueba subiendo otro con un tema distinto.',
                textAlign: TextAlign.center,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => RecommendationTile(recommendation: items![i]),
    );
  }
}

/// Una tarjeta individual de recomendación.
///
/// Se separó como widget propio (en vez de un método `_buildTile`) para
/// que Flutter pueda reconstruirlo de forma aislada — un `const`/widget
/// dedicado con su propia identidad es más barato de reconstruir que un
/// método que regenera el árbol completo en cada `build()` del padre.
class RecommendationTile extends StatelessWidget {
  final Recommendation recommendation;

  const RecommendationTile({super.key, required this.recommendation});

  Color _matchColor(ColorScheme cs) {
    final p = recommendation.matchPercent;
    if (p >= 70) return cs.primary;
    if (p >= 40) return cs.tertiary;
    return cs.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final r = recommendation;
    final matchColor = _matchColor(cs);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Cover(thumbnailUrl: r.thumbnailUrl),
          const SizedBox(width: 12),
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
                        // Antes: TextStyle(fontSize: 13.5, ...) hardcodeado.
                        // Ahora: se deriva de bodyMedium del theme, solo se
                        // ajustan peso y color puntualmente.
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _MatchBadge(percent: r.matchPercent, color: matchColor),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  r.authors.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (r.matchReason != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    r.matchReason!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: cs.primary.withOpacity(0.7),
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

class _Cover extends StatelessWidget {
  final String? thumbnailUrl;
  const _Cover({required this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 46,
        height: 64,
        child: thumbnailUrl != null
            ? Image.network(
          thumbnailUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _Placeholder(cs: cs),
        )
            : _Placeholder(cs: cs),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final ColorScheme cs;
  const _Placeholder({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.primaryContainer,
      child: Icon(
        Icons.menu_book_rounded,
        color: cs.onPrimaryContainer,
        size: 20,
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
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent%',
        style: tt.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}