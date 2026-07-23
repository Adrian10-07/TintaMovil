import 'package:flutter/material.dart';
import 'recent_document.dart';

/// Una fila/card de la lista "Recientes": ícono de tipo de archivo,
/// título + metadata real (páginas y tamaño del PDF), y a la derecha un
/// botón "Chat" o un badge de progreso de análisis. Toda la tarjeta es
/// tappable para reabrir el documento; mantener presionado ofrece borrarlo
/// de la lista.
class RecentDocumentCard extends StatelessWidget {
  final RecentDocument document;
  final DocumentTypeStyle style;
  final VoidCallback? onTap;
  final VoidCallback? onChatTap;
  final VoidCallback? onDeleteTap;

  const RecentDocumentCard({
    Key? key,
    required this.document,
    required this.style,
    this.onTap,
    this.onChatTap,
    this.onDeleteTap,
  }) : super(key: key);

  Future<void> _confirmDelete(BuildContext context) async {
    if (onDeleteTap == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar documento'),
        content: Text('¿Quitar "${document.title}" de tus recientes? No borra el archivo de tu dispositivo, solo lo quita de esta lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmar == true) onDeleteTap!();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: () => _confirmDelete(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _FileIcon(style: style),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    document.pages > 0
                        ? '${document.pages} páginas · ${document.sizeLabel}'
                        : document.sizeLabel,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.50),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            document.progress != null
                ? _ProgressBadge(progress: document.progress!)
                : _ChatButton(onTap: onChatTap),
          ],
        ),
      ),
    );
  }
}

class _FileIcon extends StatelessWidget {
  final DocumentTypeStyle style;
  const _FileIcon({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.description_rounded,
              color: style.foreground.withOpacity(0.85), size: 22),
          Positioned(
            bottom: 6,
            child: Text(
              style.label,
              style: TextStyle(
                color: style.foreground,
                fontSize: 7,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _ChatButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withOpacity(0.35)),
        backgroundColor: colorScheme.primaryContainer.withOpacity(0.30),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.auto_awesome_rounded, size: 14),
      label: const Text('Chat', style: TextStyle(fontSize: 12)),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final double progress;
  const _ProgressBadge({required this.progress});

  void _explain(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Este % indica qué tan completo salió el análisis del documento, no páginas leídas.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percent = (progress * 100).round();
    final completo = percent >= 100;

    return GestureDetector(
      onTap: () => _explain(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer.withOpacity(0.55),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              completo ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
              size: 13,
              color: colorScheme.onTertiaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}