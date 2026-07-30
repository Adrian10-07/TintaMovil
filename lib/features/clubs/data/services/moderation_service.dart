import '../../domain/entities/discussion.dart';

/// Resultado de la moderación de un mensaje.
class ModerationResult {
  final ModerationFlag flag;
  final String? reason;
  final double confidence;

  const ModerationResult({
    required this.flag,
    this.reason,
    this.confidence = 1.0,
  });

  bool get isAllowed => flag == ModerationFlag.none;
  bool get isSpoiler => flag == ModerationFlag.spoiler;
  bool get isBlocked => flag == ModerationFlag.blocked;
}

class ModerationService {
  // Patrones que indican contenido fuera de tema o inapropiado.
  // En producción esto vendría de configuración remota.
  static final _blockedPatterns = <RegExp>[
    // Contenido ilegal / drogas
    RegExp(r'\b(vend[oe]|compr[ao]|consig[oe]).{0,20}(droga|mota|hierba|coca|crack|meta|éxtasis|lsd)\b', caseSensitive: false),
    // Armas
    RegExp(r'\b(vend[oe]|compr[ao]|consig[oe]).{0,20}(arma|pistola|rifle|munición)\b', caseSensitive: false),
    // Piratería de contenido
    RegExp(r'\b(link|enlace|descarg[ao]).{0,30}(pirat|gratis|mega\.nz|torrent)\b', caseSensitive: false),
  ];

  // Patrones que indican posibles spoilers.
  static final _spoilerPatterns = <RegExp>[
    RegExp(r'\b(al final|spoiler|resulta que|el twist es|el protagonista muere|se revela que)\b', caseSensitive: false),
    RegExp(r'\b(en el (último|final) capítulo)\b', caseSensitive: false),
    RegExp(r'\b(muere|asesinan|matan) (a|al|el|la|los|las) \w+\b', caseSensitive: false),
  ];

  // Patrones de acoso / hate speech.
  static final _harassmentPatterns = <RegExp>[
    RegExp(r'\b(eres un|eres una)\s+(idiota|estúpid[oa]|imbécil|pendej[oa])\b', caseSensitive: false),
  ];

  // Spam: mensajes muy repetitivos o solo mayúsculas.
  static bool _isSpam(String content) {
    if (content.length > 20 && content == content.toUpperCase()) return true;
    // Repetición de caracteres: "jajajajajaja" > 20 chars con < 4 unique
    if (content.length > 20) {
      final unique = content.toLowerCase().split('').toSet();
      if (unique.length < 4) return true;
    }
    return false;
  }

  /// Analiza un mensaje y devuelve el resultado de moderación.
  ///
  /// Esta validación es client-side y rápida (~0ms). El servidor puede
  /// aplicar una segunda capa de moderación con IA.
  ModerationResult moderate(String content, {int? currentChapter}) {
    final trimmed = content.trim();

    // 1. Contenido bloqueado (ilegal)
    for (final pattern in _blockedPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return const ModerationResult(
          flag: ModerationFlag.blocked,
          reason: 'El mensaje contiene contenido no permitido.',
          confidence: 0.9,
        );
      }
    }

    // 2. Acoso
    for (final pattern in _harassmentPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return const ModerationResult(
          flag: ModerationFlag.blocked,
          reason: 'El mensaje contiene lenguaje ofensivo.',
          confidence: 0.85,
        );
      }
    }

    // 3. Spam
    if (_isSpam(trimmed)) {
      return const ModerationResult(
        flag: ModerationFlag.warned,
        reason: 'El mensaje parece ser spam.',
        confidence: 0.7,
      );
    }

    // 4. Spoilers
    for (final pattern in _spoilerPatterns) {
      if (pattern.hasMatch(trimmed)) {
        return const ModerationResult(
          flag: ModerationFlag.spoiler,
          reason: 'Este mensaje podría contener spoilers.',
          confidence: 0.75,
        );
      }
    }

    // 5. Todo OK
    return const ModerationResult(
      flag: ModerationFlag.none,
      confidence: 1.0,
    );
  }

  /// Verifica si un mensaje es aceptable para enviar.
  /// Retorna null si OK, o un mensaje de error descriptivo.
  String? validate(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 'El mensaje no puede estar vacío.';
    if (trimmed.length > 4000) return 'El mensaje es demasiado largo (máx. 4000 caracteres).';

    final result = moderate(trimmed);
    if (result.isBlocked) return result.reason;

    return null; // mensaje válido
  }
}
