import 'package:flutter/material.dart';

/// Header de la vista "Sube un libro": título, subtítulo de privacidad,
/// y un candado que explica qué pasa realmente con tu documento al tocarlo.
class RecommendationsHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onPrivacyTap;
  final bool showBackButton;

  const RecommendationsHeader({
    Key? key,
    required this.onBack,
    this.onPrivacyTap,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
              onPressed: onBack,
            ),
            const SizedBox(width: 4),
          ] else
            const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mis documentos', style: textTheme.titleLarge),
                Text(
                  'Subida segura · Toca el candado para detalles',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
          _PrivacyBadge(colorScheme: colorScheme, onTap: onPrivacyTap),
        ],
      ),
    );
  }
}

class _PrivacyBadge extends StatelessWidget {
  final ColorScheme colorScheme;
  final VoidCallback? onTap;
  const _PrivacyBadge({required this.colorScheme, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
      ),
    );
  }
}