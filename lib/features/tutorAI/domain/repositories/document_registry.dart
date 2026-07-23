/// Contrato del registro local de documentos.
///
/// Guarda el mapeo entre hash del PDF (SHA-256) y document_id del backend
/// para evitar re-subir PDFs ya indexados.
abstract class DocumentRegistry {
  /// Devuelve el document_id asociado a este hash, o null si no existe.
  Future<String?> getDocumentIdByHash(String hash);

  /// Guarda la asociación hash → document_id.
  Future<void> saveMapping({
    required String hash,
    required String documentId,
    required String filename,
  });

  /// Elimina una asociación (por ejemplo si el backend perdió el documento).
  Future<void> removeByHash(String hash);
}
