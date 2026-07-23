/// Fuente citada por el tutor IA cuando responde con RAG remoto.
///
/// Cada Source representa un fragmento del PDF que el LLM usó para construir
/// su respuesta. Se muestran al final del mensaje del asistente como chips
/// con "p. 15" o similar.
class TutorSource {
  final String chunkId;
  final int? pageNumber;
  final String excerpt;
  final double similarity;

  const TutorSource({
    required this.chunkId,
    required this.pageNumber,
    required this.excerpt,
    required this.similarity,
  });

  factory TutorSource.fromJson(Map<String, dynamic> json) {
    return TutorSource(
      chunkId: json['chunk_id'] as String,
      pageNumber: json['page_number'] as int?,
      excerpt: json['excerpt'] as String? ?? '',
      similarity: (json['similarity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Etiqueta corta para el chip: "p. 15" o "Fragmento" si no hay página.
  String get shortLabel {
    if (pageNumber != null) return 'p. $pageNumber';
    return 'Fragmento';
  }
}
