/// Entidad de recomendación de libro.
///
/// Es lo que devuelve el servicio de Recomendaciones en
/// GET /api/v1/recommendations, ya enriquecido con la metadata del libro
/// (título, autores, portada) que generó el motor ML (Go).
class Recommendation {
  final String id;
  final String bookId;
  final double score;
  final String source;

  // ── Metadata del libro (viene del objeto `book` embebido) ──
  final String title;
  final List<String> authors;
  final String? thumbnailUrl;
  final String? infoLink;
  final String? description;

  /// Palabras clave que más pesaron al recomendar este libro (explica el
  /// "por qué"). Puede venir vacía si el backend aún no la expone.
  final List<String> matchedKeywords;

  Recommendation({
    required this.id,
    required this.bookId,
    required this.score,
    required this.source,
    required this.title,
    required this.authors,
    this.thumbnailUrl,
    this.infoLink,
    this.description,
    this.matchedKeywords = const [],
  });

  /// Afinidad legible (score 0..1 → 0..100).
  int get matchPercent => (score.clamp(0.0, 1.0) * 100).round();

  /// Texto listo para mostrar en la UI, ej: "Coincide en: anatomía, huesos".
  /// Devuelve null si no hay palabras clave que mostrar.
  String? get matchReason {
    if (matchedKeywords.isEmpty) return null;
    return 'Coincide en: ${matchedKeywords.join(', ')}';
  }

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    final book = (json['book'] as Map<String, dynamic>?) ?? const {};

    return Recommendation(
      id: json['id']?.toString() ?? '',
      bookId: json['book_id']?.toString() ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      source: json['source']?.toString() ?? '',
      title: book['title']?.toString() ?? 'Sin título',
      authors: List<String>.from(
        book['authors'] ?? const ['Autor desconocido'],
      ),
      thumbnailUrl:
      book['thumbnail']?.toString().replaceAll('http://', 'https://'),
      infoLink: book['info_link']?.toString(),
      description: book['description']?.toString(),
      matchedKeywords: List<String>.from(book['match_keywords'] ?? const []),
    );
  }
}