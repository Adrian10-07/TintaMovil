import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';

/// Burbuja de un mensaje en el chat.
///
/// - Usuario: alineada a la derecha, fondo verde primario, texto blanco.
/// - Asistente: alineada a la izquierda, fondo gris muy claro, texto principal.
///
/// Mientras `isStreaming` es true se muestra un cursor parpadeante al final
/// del texto, simulando el typing en tiempo real.
class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isUser) return _UserBubble(message: message);
    return _AssistantBubble(message: message);
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMessage message;
  const _UserBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(left: 48, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(
          message.content,
          style: tt.bodyMedium?.copyWith(
            color: cs.onPrimary,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final ChatMessage message;
  const _AssistantBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(right: 48, bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Si está streaming y aún no hay texto, mostrar typing dots.
            if (message.isStreaming && message.content.isEmpty)
              const _TypingDots()
            else
              _RichAssistantText(
                content: message.content,
                isStreaming: message.isStreaming,
                primary: cs.primary,
                textStyle: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Texto del asistente con palabras clave resaltadas en verde primario.
/// Por ahora resalta palabras que están entre asteriscos `*texto*` al
/// estilo markdown ligero (Gemma lo emite a veces).
class _RichAssistantText extends StatelessWidget {
  final String content;
  final bool isStreaming;
  final Color primary;
  final TextStyle? textStyle;

  const _RichAssistantText({
    required this.content,
    required this.isStreaming,
    required this.primary,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final spans = _parseSpans(content, primary, textStyle);
    return RichText(
      text: TextSpan(
        style: textStyle,
        children: [
          ...spans,
          if (isStreaming) _CursorSpan(color: primary).build(),
        ],
      ),
    );
  }

  /// Parser muy simple: convierte `*texto*` en texto resaltado.
  /// No usamos `flutter_markdown` para mantener la dependencia mínima.
  List<TextSpan> _parseSpans(String text, Color hl, TextStyle? base) {
    final pattern = RegExp(r'\*([^*]+)\*');
    final out = <TextSpan>[];
    int idx = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > idx) {
        out.add(TextSpan(text: text.substring(idx, m.start)));
      }
      out.add(TextSpan(
        text: m.group(1),
        style: base?.copyWith(color: hl, fontWeight: FontWeight.w700),
      ));
      idx = m.end;
    }
    if (idx < text.length) {
      out.add(TextSpan(text: text.substring(idx)));
    }
    return out;
  }
}

class _CursorSpan {
  final Color color;
  _CursorSpan({required this.color});

  TextSpan build() {
    return TextSpan(
      text: ' ▍',
      style: TextStyle(color: color, fontWeight: FontWeight.w300),
    );
  }
}

/// Animación de 3 puntitos saltarines (typing indicator).
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 36,
      height: 16,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_ctrl.value - i * 0.2).clamp(0.0, 1.0);
              final opacity = (0.3 + (t * 0.7)).clamp(0.3, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
