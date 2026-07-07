import '../entities/document_chunk.dart';
import '../entities/indexed_document.dart';

/// Contrato del repositorio de conocimiento (base de conocimientos local).
///
/// Gestiona la indexación semántica de documentos PDF y la búsqueda
/// de fragmentos relevantes para alimentar al LLM (RAG offline).
abstract class KnowledgeRepository {
  /// Verifica si un documento ya fue indexado previamente.
  /// Usa el hash SHA-256 del archivo para identificarlo.
  Future<bool> isDocumentIndexed(String filePath);

  /// Obtiene el hash SHA-256 de un archivo PDF.
  Future<String> getDocumentHash(String filePath);

  /// Indexa un documento: extrae texto, divide en chunks, calcula TF-IDF
  /// y persiste todo en SQLite.
  ///
  /// [onProgress] emite valores de 0.0 a 1.0 para la UI.
  Future<void> indexDocument(
    String filePath, {
    String? fileName,
    void Function(double progress)? onProgress,
  });

  /// Busca los chunks más relevantes para una query dentro de un documento.
  ///
  /// Devuelve los [topK] fragmentos con mayor similitud coseno.
  Future<List<DocumentChunk>> search(
    String query, {
    required String documentHash,
    int topK = 3,
  });

  /// Obtiene los metadatos de un documento indexado.
  Future<IndexedDocument?> getIndexedDocument(String hash);

  /// Elimina el índice de un documento y sus chunks.
  Future<void> deleteDocument(String documentHash);
}
