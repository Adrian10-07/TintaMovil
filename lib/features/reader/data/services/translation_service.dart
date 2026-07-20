import 'dart:convert';
import 'package:http/http.dart' as http;

/// Traduce texto usando el endpoint público (no oficial, sin costo ni
/// API key) que expone Google Translate para su propio widget web.
/// Es el mismo mecanismo que usan varios paquetes open source de
/// traducción — no es una API oficial, así que puede fallar o dar
/// límite de uso; por eso todo el manejo de errores es explícito.
class TranslationService {
  static const _endpoint = 'https://translate.googleapis.com/translate_a/single';

  // El endpoint tiene un límite práctico por request; se parte el texto
  // en fragmentos de este tamaño (cortando en saltos de línea/párrafo
  // cuando se puede, para no partir oraciones a la mitad).
  static const _chunkSize = 3500;

  /// Traduce [text] al español ('es'). [sourceLang] es 'auto' por
  /// defecto (detecta el idioma original solo).
  static Future<String> translateToSpanish(
      String text, {
        String sourceLang = 'auto',
      }) async {
    final chunks = _splitIntoChunks(text, _chunkSize);
    final translated = <String>[];

    for (final chunk in chunks) {
      if (chunk.trim().isEmpty) {
        translated.add(chunk);
        continue;
      }
      translated.add(await _translateChunk(chunk, sourceLang));
    }

    return translated.join();
  }

  static Future<String> _translateChunk(String text, String sourceLang) async {
    final uri = Uri.parse(_endpoint).replace(queryParameters: {
      'client': 'gtx',
      'sl': sourceLang,
      'tl': 'es',
      'dt': 't',
      'q': text,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'El servicio de traducción respondió ${response.statusCode}. '
            'Puede estar temporalmente saturado — intenta de nuevo en un momento.',
      );
    }

    // La respuesta es un JSON anidado y algo peculiar:
    // [[["texto traducido","texto original",null,null,...], ...], ...]
    final decoded = json.decode(response.body) as List<dynamic>;
    final segments = decoded[0] as List<dynamic>;

    final buffer = StringBuffer();
    for (final segment in segments) {
      final translatedPiece = segment[0];
      if (translatedPiece is String) buffer.write(translatedPiece);
    }

    return buffer.toString();
  }

  /// Parte un texto largo en fragmentos, intentando cortar en un salto
  /// de párrafo cercano al límite en vez de a la mitad de una oración.
  static List<String> _splitIntoChunks(String text, int maxLength) {
    if (text.length <= maxLength) return [text];

    final chunks = <String>[];
    var remaining = text;

    while (remaining.length > maxLength) {
      var cutAt = remaining.lastIndexOf('\n\n', maxLength);
      if (cutAt < maxLength ~/ 2) {
        cutAt = remaining.lastIndexOf('. ', maxLength);
      }
      if (cutAt < maxLength ~/ 2) {
        cutAt = maxLength;
      }

      chunks.add(remaining.substring(0, cutAt));
      remaining = remaining.substring(cutAt);
    }

    if (remaining.isNotEmpty) chunks.add(remaining);
    return chunks;
  }

  /// Convierte el HTML de un capítulo de EPUB a texto plano legible,
  /// para poder mandarlo a traducir (el endpoint no entiende HTML).
  static String htmlToPlainText(String html) {
    var text = html
        .replaceAll(RegExp(r'<(br|p|div)[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // Colapsa espacios/saltos de línea repetidos.
    text = text.replaceAll(RegExp(r'[ \t]+'), ' ');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}