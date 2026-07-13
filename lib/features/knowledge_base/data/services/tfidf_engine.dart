import 'dart:math';

import '../../domain/entities/document_chunk.dart';

/// Motor de TF-IDF + Similitud Coseno en Dart puro.
///
/// No requiere ningún modelo de ML — opera con aritmética simple
/// sobre frecuencias de palabras. Suficiente para un MVP de RAG
/// offline en dispositivos móviles.
class TfidfEngine {
  // Stopwords comunes en español e inglés que no aportan significado semántico.
  static const _stopwords = <String>{
    // Español
    'de', 'la', 'que', 'el', 'en', 'y', 'a', 'los', 'del', 'se', 'las',
    'por', 'un', 'para', 'con', 'no', 'una', 'su', 'al', 'lo', 'como',
    'más', 'pero', 'sus', 'le', 'ya', 'o', 'este', 'sí', 'porque', 'esta',
    'entre', 'cuando', 'muy', 'sin', 'sobre', 'también', 'me', 'hasta',
    'hay', 'donde', 'quien', 'desde', 'todo', 'nos', 'durante', 'todos',
    'uno', 'les', 'ni', 'contra', 'otros', 'ese', 'eso', 'ante', 'ellos',
    'e', 'esto', 'mí', 'antes', 'algunos', 'qué', 'unos', 'yo', 'otro',
    'otras', 'otra', 'él', 'tanto', 'esa', 'estos', 'mucho', 'quienes',
    'nada', 'muchos', 'cual', 'poco', 'ella', 'estar', 'estas', 'algunas',
    'algo', 'nosotros', 'mi', 'mis', 'tú', 'te', 'ti', 'tu', 'tus',
    'ellas', 'nosotras', 'vosotros', 'vosotras', 'os', 'mío', 'mía',
    'es', 'son', 'fue', 'ser', 'ha', 'era', 'sido', 'tiene', 'han',
    // Inglés
    'the', 'be', 'to', 'of', 'and', 'in', 'that', 'have', 'i',
    'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do', 'at',
    'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say', 'her',
    'she', 'or', 'an', 'will', 'my', 'one', 'all', 'would', 'there',
    'their', 'what', 'so', 'up', 'out', 'if', 'about', 'who', 'get',
    'which', 'go','when', 'make', 'can', 'like', 'time',
    'just', 'him', 'know', 'take', 'people', 'into', 'year', 'your',
    'some', 'could', 'them', 'see', 'other', 'than', 'then', 'now',
    'look', 'only', 'come', 'its', 'over', 'think', 'also', 'back',
    'after', 'use', 'two', 'how', 'our', 'way', 'even', 'new',
    'want', 'because', 'any', 'these', 'give', 'day', 'most', 'us',
    'is', 'are', 'was', 'were', 'been', 'has', 'had', 'did',
  };

  /// Tokeniza un texto en términos normalizados.
  ///
  /// Proceso: minúsculas → solo letras/números → eliminar stopwords →
  /// filtrar tokens menores a 2 caracteres.
  List<String> tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1 && !_stopwords.contains(t))
        .toList();
  }

  /// Calcula el vector TF-IDF de un texto dado las frecuencias de
  /// documento del corpus.
  ///
  /// [documentFrequencies] = {término → en cuántos chunks aparece}.
  /// [totalDocs] = número total de chunks en el corpus.
  Map<String, double> computeTfidf(
    String text,
    Map<String, int> documentFrequencies,
    int totalDocs,
  ) {
    final tokens = tokenize(text);
    if (tokens.isEmpty) return {};

    // TF (Term Frequency): frecuencia normalizada del término en este texto.
    final termCounts = <String, int>{};
    for (final token in tokens) {
      termCounts[token] = (termCounts[token] ?? 0) + 1;
    }

    final vector = <String, double>{};
    for (final entry in termCounts.entries) {
      final tf = entry.value / tokens.length;
      final df = documentFrequencies[entry.key] ?? 0;
      // IDF con suavizado para evitar log(0).
      final idf = log((totalDocs + 1) / (df + 1)) + 1;
      vector[entry.key] = tf * idf;
    }

    return vector;
  }

  /// Calcula las frecuencias de documento (DF) del corpus completo.
  ///
  /// Retorna un mapa {término → cantidad de chunks que lo contienen}.
  Map<String, int> computeDocumentFrequencies(List<String> chunkTexts) {
    final df = <String, int>{};
    for (final text in chunkTexts) {
      // Usamos un Set para contar cada término una sola vez por documento.
      final uniqueTokens = tokenize(text).toSet();
      for (final token in uniqueTokens) {
        df[token] = (df[token] ?? 0) + 1;
      }
    }
    return df;
  }

  /// Similitud coseno entre dos vectores sparse.
  double cosineSimilarity(Map<String, double> a, Map<String, double> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (final entry in a.entries) {
      normA += entry.value * entry.value;
      if (b.containsKey(entry.key)) {
        dotProduct += entry.value * b[entry.key]!;
      }
    }

    for (final val in b.values) {
      normB += val * val;
    }

    final denominator = sqrt(normA) * sqrt(normB);
    if (denominator == 0) return 0.0;

    return dotProduct / denominator;
  }

  /// Rankea chunks por relevancia para una query.
  ///
  /// Calcula TF-IDF de la query usando las DFs del corpus y devuelve
  /// los [topK] chunks con mayor similitud coseno.
  List<DocumentChunk> rankChunks(
    String query,
    List<DocumentChunk> chunks, {
    int topK = 3,
  }) {
    if (chunks.isEmpty) return [];

    // Calcular DF del corpus de chunks.
    final df = computeDocumentFrequencies(
      chunks.map((c) => c.content).toList(),
    );

    // Calcular TF-IDF de la query.
    final queryVector = computeTfidf(query, df, chunks.length);
    if (queryVector.isEmpty) return chunks.take(topK).toList();

    // Puntuar cada chunk.
    final scored = <_ScoredChunk>[];
    for (final chunk in chunks) {
      final score = cosineSimilarity(queryVector, chunk.tfidfVector);
      scored.add(_ScoredChunk(chunk: chunk, score: score));
    }

    // Ordenar descendente por score.
    scored.sort((a, b) => b.score.compareTo(a.score));

    return scored.take(topK).map((s) => s.chunk).toList();
  }
}

class _ScoredChunk {
  final DocumentChunk chunk;
  final double score;

  const _ScoredChunk({required this.chunk, required this.score});
}
