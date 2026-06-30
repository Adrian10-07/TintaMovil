class Book {
  final String id;            // identificador único, ej. "mary-shelley_frankenstein"
  final String title;
  final List<String> authors;
  final String? description;
  final String? thumbnailUrl;
  final String category;      // categoría que TÚ asignas al curar el libro
  final List<String> subjects;

  // IMPORTANTE: la URL de descarga se guarda completa y verificada,
  // NO se reconstruye a partir de slugs. Algunos libros de Standard Ebooks
  // tienen un segmento extra de traductor en la URL
  // (ej. niccolo-machiavelli/the-prince/w-k-marriott), así que una fórmula
  // fija de "autor/libro" no es universal. Cada URL debe verificarse
  // manualmente una vez al curar el catálogo.
  final String epubUrl;
  final String pageUrl;

  Book({
    required this.id,
    required this.title,
    required this.authors,
    required this.epubUrl,
    required this.pageUrl,
    this.description,
    this.thumbnailUrl,
    this.category = 'General',
    this.subjects = const [],
  });

  /// Standard Ebooks siempre publica el EPUB — si está en la lista curada
  /// con su URL verificada, ya sabemos que existe y es descargable.
  bool get isReadable => true;
}