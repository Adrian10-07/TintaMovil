import 'package:flutter/material.dart';
import 'currently_reading_book.dart';
import 'currently_reading_card.dart';

/// Sección "Currently Reading": encabezado con "Ver todo" + carrusel
/// horizontal de CurrentlyReadingCard. El scroll de esta sección es
/// horizontal (Axis.horizontal), independiente del scroll vertical
/// general del Home.
class CurrentlyReadingSection extends StatelessWidget {
  final List<CurrentlyReadingBook> books;
  final VoidCallback? onSeeAllTap;
  final void Function(CurrentlyReadingBook)? onBookTap;

  const CurrentlyReadingSection({
    Key? key,
    required this.books,
    this.onSeeAllTap,
    this.onBookTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    if (books.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Leyendo actualmente', style: textTheme.titleMedium),
              InkWell(
                onTap: onSeeAllTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver todo',
                        style: textTheme.labelMedium
                            ?.copyWith(color: colorScheme.primary),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          // Scroll horizontal independiente: este carrusel NO hace
          // scroll vertical, solo lateral entre los libros.
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final book = books[index];
              return CurrentlyReadingCard(
                book: book,
                onTap: () => onBookTap?.call(book),
              );
            },
          ),
        ),
      ],
    );
  }
}