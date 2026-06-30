import 'package:flutter/material.dart';
import '../../../../../core/presentation/components/book_cover_palette.dart';
import '../../domain/entities/book.dart';

/// Header superior del detalle de libro: fondo con gradiente
/// determinístico por libro, botones flotantes (volver, guardar,
/// compartir), ícono temático, badge de categoría, título y metadata.
class BookDetailHeader extends StatelessWidget {
  final Book book;
  final VoidCallback onBack;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final bool isSaved;

  const BookDetailHeader({
    Key? key,
    required this.book,
    required this.onBack,
    this.onSave,
    this.onShare,
    this.isSaved = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gradient = BookCoverPalette.forBookId(book.id);

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopActionsRow(
            onBack: onBack,
            onSave: onSave,
            isSaved: isSaved,
            onShare: onShare,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BookIconBadge(book: book),
              const SizedBox(width: 14),
              Expanded(child: _CategoryBadge(category: book.category)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            book.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            book.authors.join(', '),
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          _MetadataRow(book: book),
        ],
      ),
    );
  }
}

class _TopActionsRow extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final bool isSaved;

  const _TopActionsRow({
    required this.onBack,
    this.onSave,
    this.onShare,
    this.isSaved = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _CircleIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
        Row(
          children: [
            _CircleIconButton(
              icon: isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              onTap: onSave,
            ),
            const SizedBox(width: 8),
            _CircleIconButton(icon: Icons.share_rounded, onTap: onShare),
          ],
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CircleIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.22),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _BookIconBadge extends StatelessWidget {
  final Book book;
  const _BookIconBadge({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Icon(
        _iconForCategory(book.category),
        color: Colors.white,
        size: 28,
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Filosofía':
        return Icons.psychology_outlined;
      case 'Ciencia':
        return Icons.science_outlined;
      case 'Estudio':
        return Icons.school_outlined;
      default:
        return Icons.auto_stories_outlined;
    }
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          category.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final Book book;
  const _MetadataRow({required this.book});

  @override
  Widget build(BuildContext context) {
    // Standard Ebooks no expone rating ni conteo de lectores; usamos
    // valores ilustrativos derivados del id del libro (consistentes,
    // no aleatorios en cada build) hasta que exista esa data real.
    final rating = _placeholderRating(book.id);
    final readers = _placeholderReaderCount(book.id);

    return Row(
      children: [
        Icon(Icons.star_rounded, color: Colors.amber.shade200, size: 18),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.people_alt_outlined,
            color: Colors.white.withOpacity(0.85), size: 16),
        const SizedBox(width: 4),
        Text(
          readers,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 16),
        Icon(Icons.menu_book_outlined,
            color: Colors.white.withOpacity(0.85), size: 16),
        const SizedBox(width: 4),
        Text(
          book.subjects.isNotEmpty ? book.subjects.first : 'Clásico',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  double _placeholderRating(String id) {
    int hash = 0;
    for (final c in id.codeUnits) hash = (hash * 31 + c) & 0x7FFFFFFF;
    return 4.0 + (hash % 10) / 10; // entre 4.0 y 4.9
  }

  String _placeholderReaderCount(String id) {
    int hash = 0;
    for (final c in id.codeUnits) hash = (hash * 17 + c) & 0x7FFFFFFF;
    final value = 1 + (hash % 50); // entre 1k y 50k
    return '${value}k';
  }
}