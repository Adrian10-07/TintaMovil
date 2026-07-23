import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../../knowledge_base/data/services/pdf_text_extractor.dart';
import '../../../knowledge_base/data/services/text_chunker.dart';
import '../../../knowledge_base/data/services/tfidf_engine.dart';
import '../../../knowledge_base/domain/entities/document_chunk.dart';

/// RAG local en memoria, SIN persistencia en disco.
class InMemoryRagService {
  final PdfTextExtractor _extractor;
  final TextChunker _chunker;
  final TfidfEngine _tfidfEngine;

  InMemoryRagService({
    PdfTextExtractor? extractor,
    TextChunker? chunker,
    TfidfEngine? tfidfEngine,
  })  : _extractor = extractor ?? PdfTextExtractor(),
        _chunker = chunker ?? TextChunker(),
        _tfidfEngine = tfidfEngine ?? TfidfEngine();

  /// Cache en memoria: hash del PDF → chunks ya indexados con su vector
  /// TF-IDF. Evita re-procesar el mismo documento en cada pregunta o al
  /// reabrir el chat dentro de la misma sesión de la app.
  final Map<String, List<DocumentChunk>> _indexCache = {};

  /// Indexa un PDF si no estaba ya en cache. Es seguro llamarlo en cada
  /// apertura del chat: si ya está indexado, no repite el trabajo.
  Future<List<DocumentChunk>> ensureIndexed({
    required String filePath,
    required String documentHash,
  }) async {
    final cached = _indexCache[documentHash];
    if (cached != null) return cached;

    final pages = await _extractor.extractText(filePath);
    if (pages.isEmpty) {
      _indexCache[documentHash] = [];
      return [];
    }

    final rawChunks = _chunker.chunkPages(pages, documentHash);
    if (rawChunks.isEmpty) {
      _indexCache[documentHash] = [];
      return [];
    }

    // Calcular TF-IDF de cada chunk usando las frecuencias del corpus
    // completo de ESTE documento (igual que hace KnowledgeRepositoryImpl,
    // solo que aquí no se persiste nada).
    final chunkTexts = rawChunks.map((c) => c.content).toList();
    final df = _tfidfEngine.computeDocumentFrequencies(chunkTexts);
    final totalDocs = rawChunks.length;

    final indexedChunks = <DocumentChunk>[];
    for (final chunk in rawChunks) {
      final vector = _tfidfEngine.computeTfidf(chunk.content, df, totalDocs);
      indexedChunks.add(chunk.copyWith(tfidfVector: vector));
    }

    _indexCache[documentHash] = indexedChunks;
    return indexedChunks;
  }


  List<DocumentChunk> search({
    required String query,
    required String documentHash,
    int topK = 3,
    double minSimilarity = 0.08,
  }) {
    final chunks = _indexCache[documentHash];
    if (chunks == null || chunks.isEmpty) return [];

    // rankChunks no filtra por umbral, solo ordena — replicamos aquí la
    // lógica de scoring para poder aplicar el corte de relevancia.
    final df = _tfidfEngine.computeDocumentFrequencies(
      chunks.map((c) => c.content).toList(),
    );
    final queryVector = _tfidfEngine.computeTfidf(query, df, chunks.length);
    if (queryVector.isEmpty) return [];

    final scored = chunks
        .map((c) => (
    chunk: c,
    score: _tfidfEngine.cosineSimilarity(queryVector, c.tfidfVector),
    ))
        .where((s) => s.score >= minSimilarity)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored.take(topK).map((s) => s.chunk).toList();
  }

  /// Libera el índice de un documento (por ejemplo si se quiere forzar
  /// re-indexación tras editar el archivo).
  void invalidate(String documentHash) {
    _indexCache.remove(documentHash);
  }

  /// Hash del PDF para identificarlo como clave del cache en memoria.
  /// Streaming: no carga el archivo completo en RAM solo para hashear.
  static Future<String> computeFileHash(String filePath) async {
    final stream = File(filePath).openRead();
    final digest = await stream.transform(sha256).single;
    return digest.toString();
  }

  // ── Detección de preguntas "amplias" sobre todo el documento ────────
  // Igual que en el backend remoto: preguntas tipo "resume", "tema
  // central", etc. no se parecen semánticamente a ningún chunk puntual,
  // así que se les aplica un umbral más permisivo en vez del estricto.
  static final RegExp _broadQuestionRegex = RegExp(
    r'resum(e|en|ir)|'
    r'ideas?\s+principal|'
    r'tema\s+central|'
    r'de\s+qu[ée]\s+trata|'
    r'sobre\s+qu[ée]\s+trata|'
    r'ejemplos?\s+del?\s+concepto|'
    r'conceptos?\s+clave|'
    r'qu[ée]\s+dice\s+el\s+documento|'
    r'contenido\s+del\s+documento|'
    r'explica(me)?\s+el\s+documento|'
    r'de\s+qu[ée]\s+se\s+trata',
    caseSensitive: false,
  );

  static bool isBroadQuestion(String question) {
    return _broadQuestionRegex.hasMatch(question);
  }
}
