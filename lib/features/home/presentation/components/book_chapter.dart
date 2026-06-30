/// Representa un capítulo dentro del detalle del libro, con su estado
/// de lectura. Por ahora con datos mock — epub_view no expone una
/// tabla de contenidos independiente del lector, y el modelo Book aún
/// no trackea progreso por capítulo. Cuando exista esa persistencia,
/// este modelo se alimenta de datos reales.
class BookChapter {
  final String title;
  final bool isRead;

  const BookChapter({required this.title, required this.isRead});
}

/// Genera una lista de capítulos de ejemplo, determinística por libro
/// (mismo id siempre da los mismos capítulos "leídos"), para que la
/// UI se vea consistente sin necesitar datos reales todavía.
List<BookChapter> mockChaptersForBook(String bookId, {int total = 20}) {
  int hash = 0;
  for (final c in bookId.codeUnits) {
    hash = (hash * 31 + c) & 0x7FFFFFFF;
  }
  final readCount = 1 + (hash % 3); // entre 1 y 3 capítulos "leídos"

  const sampleTitles = [
    'Introducción',
    'El comienzo',
    'Primeros pasos',
    'El despertar',
    'Encuentros',
  ];

  return List.generate(total, (index) {
    final title = index < sampleTitles.length
        ? sampleTitles[index]
        : 'Capítulo ${index + 1}';
    return BookChapter(title: title, isRead: index < readCount);
  });
}