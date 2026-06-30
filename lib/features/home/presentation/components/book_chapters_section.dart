import 'package:flutter/material.dart';
import 'book_chapter.dart';

/// Sección "Capítulos": encabezado con contador de progreso (ej. "2 de
/// 20 leídos") y una lista corta de filas con checkmark de estado.
/// Solo muestra los primeros [previewCount] capítulos para no saturar
/// la pantalla de detalle; el resto se vería en el lector mismo.
class BookChaptersSection extends StatelessWidget {
  final List<BookChapter> chapters;
  final int previewCount;

  const BookChaptersSection({
    Key? key,
    required this.chapters,
    this.previewCount = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final readCount = chapters.where((c) => c.isRead).length;
    final preview = chapters.take(previewCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Capítulos', style: textTheme.titleLarge),
            Text(
              '$readCount de ${chapters.length} leídos',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(preview.length, (index) {
          final chapter = preview[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == preview.length - 1 ? 0 : 10,
            ),
            child: _ChapterRow(chapter: chapter),
          );
        }),
      ],
    );
  }
}

class _ChapterRow extends StatelessWidget {
  final BookChapter chapter;
  const _ChapterRow({required this.chapter});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: chapter.isRead
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: chapter.isRead
                ? Icon(Icons.check_rounded,
                size: 15, color: colorScheme.onPrimary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              chapter.title,
              style: textTheme.bodyMedium?.copyWith(
                color: chapter.isRead
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withOpacity(0.55),
                fontWeight: chapter.isRead ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}