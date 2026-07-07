import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../domain/entities/document_chunk.dart';
import '../../domain/entities/indexed_document.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../datasources/knowledge_local_datasource.dart';
import '../services/pdf_text_extractor.dart';
import '../services/text_chunker.dart';
import '../services/tfidf_engine.dart';

/// Implementación concreta del repositorio de conocimiento.
///
/// Orquesta el flujo completo de indexación RAG:
///   1. Extraer texto del PDF → [PdfTextExtractor]
///   2. Dividir en chunks → [TextChunker]
///   3. Calcular TF-IDF → [TfidfEngine]
///   4. Persistir en SQLite → [KnowledgeLocalDatasource]
///   5. Buscar por similitud coseno → [TfidfEngine]
class KnowledgeRepositoryImpl implements KnowledgeRepository {
  final PdfTextExtractor _pdfExtractor;
  final TextChunker _chunker;
  final TfidfEngine _tfidfEngine;
  final KnowledgeLocalDatasource _datasource;

  KnowledgeRepositoryImpl({
    required PdfTextExtractor pdfExtractor,
    required TextChunker chunker,
    required TfidfEngine tfidfEngine,
    required KnowledgeLocalDatasource datasource,
  })  : _pdfExtractor = pdfExtractor,
        _chunker = chunker,
        _tfidfEngine = tfidfEngine,
        _datasource = datasource;

  @override
  Future<String> getDocumentHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  @override
  Future<bool> isDocumentIndexed(String filePath) async {
    final hash = await getDocumentHash(filePath);
    return _datasource.isDocumentIndexed(hash);
  }

  @override
  Future<void> indexDocument(
    String filePath, {
    String? fileName,
    void Function(double progress)? onProgress,
  }) async {
    final hash = await getDocumentHash(filePath);
    onProgress?.call(0.05);

    // Si ya está indexado, no re-procesar.
    if (await _datasource.isDocumentIndexed(hash)) {
      onProgress?.call(1.0);
      return;
    }

    // 1. Extraer texto (40% del progreso).
    final pages = await _pdfExtractor.extractText(filePath);
    onProgress?.call(0.40);

    if (pages.isEmpty) {
      // PDF sin texto extraíble (ej. solo imágenes). Guardar documento vacío.
      await _datasource.saveDocument(IndexedDocument(
        hash: hash,
        fileName: fileName ?? filePath.split('/').last.split('\\').last,
        totalChunks: 0,
        indexedAt: DateTime.now(),
      ));
      onProgress?.call(1.0);
      return;
    }

    // 2. Dividir en chunks (60% del progreso).
    final chunks = _chunker.chunkPages(pages, hash);
    onProgress?.call(0.60);

    // 3. Calcular TF-IDF para cada chunk (85% del progreso).
    final chunkTexts = chunks.map((c) => c.content).toList();
    final df = _tfidfEngine.computeDocumentFrequencies(chunkTexts);
    final totalDocs = chunks.length;

    final indexedChunks = <DocumentChunk>[];
    for (int i = 0; i < chunks.length; i++) {
      final vector = _tfidfEngine.computeTfidf(
        chunks[i].content,
        df,
        totalDocs,
      );
      indexedChunks.add(chunks[i].copyWith(tfidfVector: vector));

      // Emitir progreso granular durante el cálculo de TF-IDF.
      if (i % 50 == 0) {
        final tfidfProgress = 0.60 + (0.25 * i / chunks.length);
        onProgress?.call(tfidfProgress);
      }
    }
    onProgress?.call(0.85);

    // 4. Persistir en SQLite (100% del progreso).
    await _datasource.saveChunks(indexedChunks);
    await _datasource.saveDocument(IndexedDocument(
      hash: hash,
      fileName: fileName ?? filePath.split('/').last.split('\\').last,
      totalChunks: indexedChunks.length,
      indexedAt: DateTime.now(),
    ));
    onProgress?.call(1.0);
  }

  @override
  Future<List<DocumentChunk>> search(
    String query, {
    required String documentHash,
    int topK = 3,
  }) async {
    final chunks = await _datasource.getChunks(documentHash);
    if (chunks.isEmpty) return [];

    return _tfidfEngine.rankChunks(query, chunks, topK: topK);
  }

  @override
  Future<IndexedDocument?> getIndexedDocument(String hash) {
    return _datasource.getDocument(hash);
  }

  @override
  Future<void> deleteDocument(String documentHash) {
    return _datasource.deleteDocument(documentHash);
  }
}
