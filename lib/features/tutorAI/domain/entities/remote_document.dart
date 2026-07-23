/// Estados del pipeline de ingesta en el backend tutor-ai.
enum RemoteDocumentStatus {
  pending,
  processing,
  ready,
  failed;

  static RemoteDocumentStatus fromString(String s) {
    return RemoteDocumentStatus.values.firstWhere(
          (v) => v.name == s,
      orElse: () => RemoteDocumentStatus.failed,
    );
  }

  bool get isTerminal =>
      this == RemoteDocumentStatus.ready || this == RemoteDocumentStatus.failed;
}

/// Representación de un documento subido al backend.
class RemoteDocument {
  final String id;
  final String filename;
  final int? totalPages;
  final RemoteDocumentStatus status;
  final String? errorMessage;
  final int chunksCount;

  const RemoteDocument({
    required this.id,
    required this.filename,
    required this.status,
    this.totalPages,
    this.errorMessage,
    this.chunksCount = 0,
  });

  factory RemoteDocument.fromJson(Map<String, dynamic> json) {
    return RemoteDocument(
      id: json['id'] as String,
      filename: json['filename'] as String,
      totalPages: json['total_pages'] as int?,
      status: RemoteDocumentStatus.fromString(json['status'] as String),
      errorMessage: json['error_message'] as String?,
      chunksCount: json['chunks_count'] as int? ?? 0,
    );
  }

  bool get isReady => status == RemoteDocumentStatus.ready;
  bool get isFailed => status == RemoteDocumentStatus.failed;
}
