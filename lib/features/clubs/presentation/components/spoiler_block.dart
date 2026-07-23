import 'package:flutter/material.dart';

import '../../domain/entities/discussion.dart';

/// Bloque colapsable para mensajes marcados como spoiler.
///
/// Muestra una advertencia y permite al usuario revelar el contenido
/// tocando el bloque.
class SpoilerBlock extends StatefulWidget {
  final Discussion message;
  final bool isMine;

  const SpoilerBlock({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  State<SpoilerBlock> createState() => _SpoilerBlockState();
}

class _SpoilerBlockState extends State<SpoilerBlock> {
  bool _isRevealed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment:
          widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        child: Card(
          color: colorScheme.tertiaryContainer.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.tertiary.withOpacity(0.3),
            ),
          ),
          child: InkWell(
            onTap: () => setState(() => _isRevealed = !_isRevealed),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header de spoiler
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Posible spoiler',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _isRevealed
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 14,
                        color: colorScheme.tertiary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Contenido (oculto o revelado)
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _isRevealed
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Text(
                      'Toca para revelar el contenido',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer
                            .withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    secondChild: Text(
                      widget.message.content,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),

                  // Timestamp
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(widget.message.createdAt),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onTertiaryContainer.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
