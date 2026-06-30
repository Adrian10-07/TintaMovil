import 'package:flutter/material.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';
import '../../domain/entities/book.dart';
import '../../../../core/presentation/components/tinta_background.dart';

class BookDetailView extends StatelessWidget {
  const BookDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final book = ModalRoute.of(context)!.settings.arguments as Book;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: TintaBackground(
        blobs: [
          BlobConfig(top: -80, right: -60, color: colorScheme.primary, size: 280, opacity: 0.12),
          BlobConfig(bottom: -100, left: -80, color: MaterialTheme.warmGold, size: 250, opacity: 0.08),
        ],
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              backgroundColor: colorScheme.surface,
              flexibleSpace: FlexibleSpaceBar(background: _BookCover(book: book)),
              leading: _BackButton(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title, style: textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      book.authors.join(', '),
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.60),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.lock_open_rounded,
                          label: 'EPUB disponible',
                          highlight: true,
                        ),
                        _InfoChip(
                          icon: book.category == 'Estudio' || book.category == 'Ciencia' || book.category == 'Filosofía'
                              ? Icons.school_rounded
                              : Icons.menu_book_rounded,
                          label: book.category,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (book.subjects.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: book.subjects
                            .map((s) => _SubjectTag(label: s))
                            .toList(),
                      ),
                      const SizedBox(height: 28),
                    ] else
                      const SizedBox(height: 28),

                    if (book.description != null && book.description!.isNotEmpty) ...[
                      Text('Sinopsis', style: textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Text(
                        book.description!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.75),
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/reader',
                            arguments: book,
                          );
                        },
                        icon: const Icon(Icons.auto_stories_rounded),
                        label: const Text('Leer libro completo'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  final Book book;
  const _BookCover({required this.book});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cs.primary.withOpacity(0.08), cs.surface],
        ),
      ),
      child: Center(
        child: Hero(
          tag: 'book-cover-${book.id}',
          child: Container(
            width: 160, height: 230,
            margin: const EdgeInsets.only(top: 60),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: cs.shadow.withOpacity(0.20), blurRadius: 24, offset: const Offset(0, 12))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: book.thumbnailUrl != null
                  ? Image.network(
                book.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _CoverPlaceholder(title: book.title),
              )
                  : _CoverPlaceholder(title: book.title),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final String title;
  const _CoverPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: cs.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;
  const _InfoChip({required this.icon, required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight ? cs.primaryContainer : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: highlight ? cs.primary : cs.onSurface.withOpacity(0.55)),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: highlight ? cs.onPrimaryContainer : cs.onSurface.withOpacity(0.70),
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ]),
    );
  }
}

class _SubjectTag extends StatelessWidget {
  final String label;
  const _SubjectTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: cs.onSecondaryContainer,
        ),
      ),
    );
  }
}