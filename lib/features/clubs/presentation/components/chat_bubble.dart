import 'package:flutter/material.dart';

import '../../domain/entities/discussion.dart';

/// Burbuja de chat con diseño moderno inspirado en apps de mensajería.
///
/// Muestra el nombre del autor, contenido, hora, y tail visual.
/// Material 3 theming — sin colores hardcodeados.
class ChatBubble extends StatelessWidget {
  final Discussion message;
  final bool isMine;
  final bool isBlocked;
  final bool showSenderName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.isBlocked = false,
    this.showSenderName = true,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bubbleColor = isBlocked
        ? colorScheme.errorContainer
        : isMine
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;

    final textColor = isBlocked
        ? colorScheme.onErrorContainer
        : isMine
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: 2,
        left: isMine ? 48 : 0,
        right: isMine ? 0 : 48,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: _hasActions ? () => _showActions(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre del remitente
                if (!isMine && showSenderName)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.userName ?? _shortUserId(message.userId),
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _senderColor(message.userId, colorScheme),
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
                          'Mensaje moderado automáticamente.',
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
                    style: textTheme.bodyMedium?.copyWith(color: textColor),
                  ),

                // Hora
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: textColor.withOpacity(0.55),
                      ),
                    ),
                    if (isMine && !isBlocked) ...[
                      const SizedBox(width: 3),
                      Icon(
                        Icons.done_all_rounded,
                        size: 13,
                        color: colorScheme.primary.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasActions => onEdit != null || onDelete != null;

  /// Color único por usuario basado en hash del userId.
  Color _senderColor(String userId, ColorScheme cs) {
    final palette = [
      cs.primary,
      cs.secondary,
      cs.tertiary,
      cs.error,
    ];
    return palette[userId.hashCode.abs() % palette.length];
  }

  String _shortUserId(String userId) {
    if (userId.length <= 8) return userId;
    return userId.substring(0, 8);
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Editar mensaje'),
                onTap: () { Navigator.pop(context); onEdit!(); },
              ),
            if (onDelete != null)
              ListTile(
                leading: Icon(Icons.delete_rounded,
                    color: Theme.of(context).colorScheme.error),
                title: Text('Eliminar mensaje',
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () { Navigator.pop(context); onDelete!(); },
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
    if (diff.inHours < 1) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}';
  }
}
