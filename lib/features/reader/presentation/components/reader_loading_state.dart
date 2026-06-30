import 'package:flutter/material.dart';
import '../../../home/domain/entities/book.dart';

/// Pantalla de carga mientras se descarga el EPUB.
/// Muestra la portada del libro (si existe) con efecto de pulso,
/// dando contexto visual de qué se está cargando.
class ReaderLoadingState extends StatelessWidget {
  final Book book;
  const ReaderLoadingState({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (book.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                book.thumbnailUrl!,
                width: 120,
                height: 170,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _PlaceholderCover(
                  title: book.title,
                  colorScheme: colorScheme,
                ),
              ),
            )
          else
            _PlaceholderCover(title: book.title, colorScheme: colorScheme),
          const SizedBox(height: 24),
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Descargando libro...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.60),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            book.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.40),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCover extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;
  const _PlaceholderCover({required this.title, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 170,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.menu_book_rounded,
        size: 36,
        color: colorScheme.onPrimaryContainer.withOpacity(0.5),
      ),
    );
  }
}