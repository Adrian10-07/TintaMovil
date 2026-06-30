import 'package:flutter/material.dart';

/// Header de la vista "Sube un libro": título, subtítulo de privacidad,
/// y un badge de candado indicando que el procesamiento es local.
class RecommendationsHeader extends StatelessWidget {
  final VoidCallback onBack;
  const RecommendationsHeader({Key? key, required this.onBack})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 22),
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mis documentos', style: textTheme.titleLarge),
                Text(
                  'Procesado localmente · Nunca se sube',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          _PrivacyBadge(colorScheme: colorScheme),
        ],
      ),
    );
  }
}

class _PrivacyBadge extends StatelessWidget {
  final ColorScheme colorScheme;
  const _PrivacyBadge({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.lock_outline_rounded,
        size: 18,
        color: colorScheme.primary,
      ),
    );
  }
}
