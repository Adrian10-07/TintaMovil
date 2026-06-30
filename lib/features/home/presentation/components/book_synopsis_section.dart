import 'package:flutter/material.dart';

/// Sección "Sinopsis": muestra la descripción truncada a unas pocas
/// líneas con un enlace "Leer más" que expande el texto completo.
class BookSynopsisSection extends StatefulWidget {
  final String description;
  const BookSynopsisSection({Key? key, required this.description})
      : super(key: key);

  @override
  State<BookSynopsisSection> createState() => _BookSynopsisSectionState();
}

class _BookSynopsisSectionState extends State<BookSynopsisSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sinopsis', style: textTheme.titleLarge),
        const SizedBox(height: 10),
        Text(
          widget.description,
          maxLines: _expanded ? null : 4,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.75),
            height: 1.6,
          ),
        ),
        if (!_expanded)
          GestureDetector(
            onTap: () => setState(() => _expanded = true),
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Leer más',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}