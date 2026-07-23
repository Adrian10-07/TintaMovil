import 'package:flutter/material.dart';
import 'currently_reading_book.dart';

/// Card grande de "Currently Reading": fondo de color sólido con blobs
/// decorativos sutiles, ícono temático arriba, título/autor abajo, y
/// el número de páginas del libro.
class CurrentlyReadingCard extends StatelessWidget {
  final CurrentlyReadingBook book;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CurrentlyReadingCard({
    Key? key,
    required this.book,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 168,
        height: 190,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: book.accentColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(book.icon, color: Colors.white, size: 26),
                const Spacer(),
                Text(
                  book.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${book.totalPages} páginas',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}