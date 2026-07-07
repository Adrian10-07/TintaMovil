/// Entidad: metadatos de un documento ya indexado.
///
/// Se usa para saber si un PDF ya fue procesado previamente y evitar
/// re-indexarlo cada vez que se abre.
class IndexedDocument {
  final String hash;
  final String fileName;
  final int totalChunks;
  final DateTime indexedAt;

  const IndexedDocument({
    required this.hash,
    required this.fileName,
    required this.totalChunks,
    required this.indexedAt,
  });
}
