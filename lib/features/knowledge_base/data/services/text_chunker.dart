import '../../domain/entities/document_chunk.dart';
import 'pdf_text_extractor.dart';

/// Servicio que divide texto extraído de un PDF en chunks de ~300 palabras
/// con overlap de 50 palabras.
///
/// El overlap garantiza que las ideas que caen en el borde de un chunk
/// no se pierdan completamente — aparecen en el chunk anterior y en el
/// siguiente.
class TextChunker {
  static const int _targetWords = 300;
  static const int _overlapWords = 50;

  /// Divide las páginas extraídas en chunks.
  ///
  /// Cada chunk tiene asociado el número de página donde comienza
  /// para poder mostrar al usuario "Fuente: página X" en el futuro.
  List<DocumentChunk> chunkPages(List<PageText> pages, String documentHash) {
    // Concatenar todo el texto con marcadores de página.
    final allWords = <_WordWithPage>[];
    for (final page in pages) {
      final words = page.text.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.isNotEmpty) {
          allWords.add(_WordWithPage(word: word, page: page.pageNumber));
        }
      }
    }

    if (allWords.isEmpty) return [];

    final chunks = <DocumentChunk>[];
    int start = 0;
    int chunkIndex = 0;

    while (start < allWords.length) {
      final end = (start + _targetWords).clamp(0, allWords.length);
      final chunkWords = allWords.sublist(start, end);

      final content = chunkWords.map((w) => w.word).join(' ');
      final pageNumber = chunkWords.first.page;

      chunks.add(DocumentChunk(
        documentHash: documentHash,
        chunkIndex: chunkIndex,
        content: content,
        pageNumber: pageNumber,
      ));

      chunkIndex++;

      // Avanzar restando el overlap para que el siguiente chunk
      // repita las últimas _overlapWords palabras.
      start += _targetWords - _overlapWords;
    }

    return chunks;
  }
}

class _WordWithPage {
  final String word;
  final int page;

  const _WordWithPage({required this.word, required this.page});
}
