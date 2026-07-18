import 'package:flutter/material.dart';

/// Tarjeta de libro individual en el catálogo.
///
/// Muestra portada, título y autores.
/// Recibe un objeto [book] con las propiedades:
///   - title (String)
///   - authors (List<String>)
///   - thumbnailUrl (String?)
class BookCard extends StatelessWidget {
  final dynamic book;
  final VoidCallback? onTap;

  const BookCard({
    Key? key,
    required this.book,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap ?? () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _BookThumbnail(thumbnailUrl: book.thumbnailUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.authors.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.50),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colorScheme.onSurface.withOpacity(0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookThumbnail extends StatelessWidget {
  final String? thumbnailUrl;

  const _BookThumbnail({required this.thumbnailUrl});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: thumbnailUrl != null
          ? Image.network(
        thumbnailUrl!,
        width: 60,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _BookPlaceholder(colorScheme: colorScheme),
      )
          : _BookPlaceholder(colorScheme: colorScheme),
    );
  }
}

class _BookPlaceholder extends StatelessWidget {
  final ColorScheme colorScheme;

  const _BookPlaceholder({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.onPrimaryContainer,
            colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('📖', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}