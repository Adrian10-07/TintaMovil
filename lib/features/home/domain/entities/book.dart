class Book {
  final String id;
  final String title;
  final List<String> authors;
  final String? description;
  final String? thumbnailUrl;
  final String? previewLink;

  // ── Campos de lectura
  final String? webReaderLink;
  final String viewability; // ALL_PAGES, PARTIAL, NO_PAGES, UNKNOWN
  final bool embeddable;
  final int pageCount;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    this.description,
    this.thumbnailUrl,
    this.previewLink,
    this.webReaderLink,
    this.viewability = 'UNKNOWN',
    this.embeddable = false,
    this.pageCount = 0,
  });

  /// ¿Se puede leer (al menos parcialmente) en el visor?
  bool get isReadable =>
      webReaderLink != null &&
          (viewability == 'ALL_PAGES' || viewability == 'PARTIAL');

  /// ¿Es dominio público con acceso completo?
  bool get isFullAccess => viewability == 'ALL_PAGES';

  /// Etiqueta legible del nivel de acceso.
  String get accessLabel {
    switch (viewability) {
      case 'ALL_PAGES':
        return 'Libro completo';
      case 'PARTIAL':
        return 'Vista previa';
      case 'NO_PAGES':
        return 'Sin preview';
      default:
        return 'Desconocido';
    }
  }
}