/// Entidad pura: un mensaje del chat con el tutor IA.
///
/// Vive solo en memoria durante la sesión. No se persiste todavía.
///
/// El rol distingue quién emitió el mensaje:
///   - [ChatRole.user]: el estudiante.
///   - [ChatRole.assistant]: Tinta AI (Gemma 2 2B corriendo on-device).
///   - [ChatRole.system]: prompt inicial que define la personalidad del tutor
///     (no se renderiza en la UI, solo se envía al modelo).
enum ChatRole { user, assistant, system }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  /// `true` mientras el modelo aún está generando tokens para este mensaje.
  /// Permite a la UI mostrar el cursor parpadeante o el indicador de typing.
  final bool isStreaming;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
  });

  /// Crea una copia inmutable con campos sustituidos.
  /// Útil durante el streaming: cada token recibido genera un nuevo
  /// ChatMessage con `content` actualizado.
  ChatMessage copyWith({
    String? content,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      content: content ?? this.content,
      timestamp: timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }

  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;
  bool get isSystem => role == ChatRole.system;
}
