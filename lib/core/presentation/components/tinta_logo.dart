import 'package:flutter/material.dart';

/// Wordmark de Tinta: ícono + texto "tinta".
///
/// Se adapta automáticamente al tema (colores del ColorScheme).
class TintaLogo extends StatelessWidget {
  final double iconSize;
  final double fontSize;

  const TintaLogo({
    Key? key,
    this.iconSize = 42,
    this.fontSize = 28,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            color: colorScheme.onPrimary,
            size: iconSize * 0.52,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'tinta',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}