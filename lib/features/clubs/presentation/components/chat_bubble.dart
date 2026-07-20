import 'package:flutter/material.dart';

import '../../domain/entities/discussion.dart';

/// Burbuja de chat para un mensaje de discusión.
///
/// Se alinea a la derecha si es propio, a la izquierda si es de otro usuario.
/// Usa colores del Material 3 theme del proyecto.
class ChatBubble extends StatelessWidget {
  final Discussion message;
  final bool isMine;
  final bool isBlocked;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.isBlocked = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress:
            (onEdit != null || onDelete != null) ? () => _showMenu(context) : null,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isBlocked
                ? colorScheme.errorContainer.withOpacity(0.5)
                : isMine
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Nombre del usuario (solo para mensajes de otros).
              if (!isMine && message.userName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.userName!,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

              // Contenido
              if (isBlocked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.block_rounded,
                        size: 14, color: colorScheme.error),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Este mensaje fue moderado automáticamente.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  message.content,
                  style: textTheme.bodyMedium?.copyWith(
                    color: isMine
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                ),

              // Timestamp
              const SizedBox(height: 4),
              Text(
                _formatTime(message.createdAt),
                style: textTheme.labelSmall?.copyWith(
                  color: (isMine
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant)
                      .withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_rounded,
                    color: Theme.of(context).colorScheme.error),
                title: Text('Eliminar',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'hace ${diff.inDays}d';

    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
