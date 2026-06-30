import '../../domain/entities/chat_message.dart';

/// DTO de un mensaje del chat. Hoy solo se usa para mapear al formato
/// que espera Gemma (rol + contenido). Cuando se agregue persistencia
/// con sqflite, este modelo crecerá con `toMap`/`fromMap`.
class ChatMessageModel {
  static Map<String, String> toGemmaFormat(ChatMessage msg) {
    return {
      'role': _roleToString(msg.role),
      'content': msg.content,
    };
  }

  static String _roleToString(ChatRole role) {
    switch (role) {
      case ChatRole.user:
        return 'user';
      case ChatRole.assistant:
        return 'assistant';
      case ChatRole.system:
        return 'system';
    }
  }
}
