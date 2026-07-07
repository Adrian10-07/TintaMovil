/// Entidad: fragmento de texto extraído de un documento PDF.
///
/// Cada chunk representa un párrafo de ~300 palabras del documento original.
/// El [tfidfVector] contiene los pesos TF-IDF pre-calculados para búsqueda
/// rápida por similitud coseno.
class DocumentChunk {
  final int? id;
  final String documentHash;
  final int chunkIndex;
  final String content;
  final int pageNumber;

  /// Vector TF-IDF: mapa de {término → peso}.
  /// Se serializa como JSON en SQLite.
  final Map<String, double> tfidfVector;

  const DocumentChunk({
    this.id,
    required this.documentHash,
    required this.chunkIndex,
    required this.content,
    required this.pageNumber,
    this.tfidfVector = const {},
  });

  DocumentChunk copyWith({
    int? id,
    Map<String, double>? tfidfVector,
  }) {
    return DocumentChunk(
      id: id ?? this.id,
      documentHash: documentHash,
      chunkIndex: chunkIndex,
      content: content,
      pageNumber: pageNumber,
      tfidfVector: tfidfVector ?? this.tfidfVector,
    );
  }
}
