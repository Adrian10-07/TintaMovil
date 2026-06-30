import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import '../../../home/domain/entities/book.dart';

/// AppBar del lector: muestra título y autor del libro, y debajo
/// (mientras se lee) el nombre del capítulo actual, usando el widget
/// oficial EpubViewActualChapter de epub_view.
class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Book book;
  final EpubController? controller;

  const ReaderAppBar({Key? key, required this.book, required this.controller})
      : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            book.title,
            style: Theme.of(context).textTheme.titleSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (controller != null)
            EpubViewActualChapter(
              controller: controller!,
              builder: (chapterValue) {
                final chapterTitle =
                chapterValue?.chapter?.Title?.trim().replaceAll('\n', '');
                return Text(
                  chapterTitle?.isNotEmpty == true
                      ? chapterTitle!
                      : book.authors.join(', '),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              },
            )
          else
            Text(
              book.authors.join(', '),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.55),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}