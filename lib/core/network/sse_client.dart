import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Cliente ligero para consumir Server-Sent Events (SSE).
///
/// El backend tutor-ai devuelve responses con Content-Type: text/event-stream
/// donde cada evento tiene el formato:
///
///     data: {"token": "hola"}
///     \n
///     data: {"done": true, "sources": [...]}
///     \n
///
/// Este cliente parsea ese stream y emite cada objeto JSON como un
/// Map<String, dynamic>. La capa que lo consume decide qué significa cada
/// evento (token, done, error).
class SseClient {
  final http.Client _client;

  SseClient({http.Client? client}) : _client = client ?? http.Client();

  /// Ejecuta un POST a [url] con [body] JSON y devuelve un Stream de los
  /// objetos JSON decodificados de cada evento SSE.
  Stream<Map<String, dynamic>> post({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async* {
    final request = http.Request('POST', Uri.parse(url));
    request.body = json.encode(body);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
      ...?headers,
    });

    final response = await _client.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = await response.stream.bytesToString();
      throw SseException(
        'SSE request falló: HTTP ${response.statusCode}\n$errorBody',
        response.statusCode,
      );
    }

    final lineStream = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final buffer = StringBuffer();

    await for (final line in lineStream) {
      if (line.isEmpty) {
        // Fin de un evento SSE: procesar el buffer
        final data = buffer.toString();
        buffer.clear();
        if (data.isEmpty) continue;

        try {
          final decoded = json.decode(data);
          if (decoded is Map<String, dynamic>) {
            yield decoded;
          }
        } catch (_) {
          // Ignorar líneas malformadas
        }
      } else if (line.startsWith('data:')) {
        final payload = line.substring(5).trimLeft();
        buffer.write(payload);
      }
      // Ignorar líneas de comentario o eventos con `event:`
    }

    if (buffer.isNotEmpty) {
      try {
        final decoded = json.decode(buffer.toString());
        if (decoded is Map<String, dynamic>) {
          yield decoded;
        }
      } catch (_) {}
    }
  }

  void close() {
    _client.close();
  }
}

class SseException implements Exception {
  final String message;
  final int statusCode;

  SseException(this.message, this.statusCode);

  @override
  String toString() => message;
}
