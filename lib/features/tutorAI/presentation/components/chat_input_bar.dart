import 'package:flutter/material.dart';

/// Input pill del chat con botón circular verde de enviar.
///
/// Inspirado en el Figma: campo gris claro con esquinas muy redondeadas,
/// botón verde primario al lado con icono `send`. Se deshabilita cuando
/// no se puede enviar (modelo cargando o respuesta en curso).
class ChatInputBar extends StatefulWidget {
  final bool enabled;
  final String hintText;
  final ValueChanged<String> onSend;

  const ChatInputBar({
    super.key,
    required this.enabled,
    required this.onSend,
    this.hintText = 'Pregúntale a Tinta AI…',
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Input ─────────────────────────────────────────────
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  maxHeight: 140,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Botón enviar ──────────────────────────────────────
            _SendButton(
              enabled: widget.enabled,
              onTap: _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _SendButton({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: enabled ? cs.primary : cs.primary.withOpacity(0.4),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            Icons.arrow_upward_rounded,
            color: cs.onPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}
