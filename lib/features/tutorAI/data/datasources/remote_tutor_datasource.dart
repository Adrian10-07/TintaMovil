import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/network/http_client.dart';
import '../../../../core/network/sse_client.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/remote_document.dart';
import '../../domain/entities/tutor_source.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Evento del stream del chat remoto.
sealed class RemoteChatEvent {
  const RemoteChatEvent();
}

class RemoteTokenEvent extends RemoteChatEvent {
  final String token;
  const RemoteTokenEvent(this.token);
}

class RemoteDoneEvent extends RemoteChatEvent {
  final List<TutorSource> sources;
  const RemoteDoneEvent(this.sources);
}

class RemoteErrorEvent extends RemoteChatEvent {
  final String message;
  const RemoteErrorEvent(this.message);
}

/// Datasource remoto: llama al microservicio tutor-ai vía HTTP + SSE.
///
/// Endpoints consumidos:
///   POST /api/v1/tutor/documents          - subir PDF (multipart)
///   GET  /api/v1/tutor/documents/{id}     - consultar estado
///   POST /api/v1/tutor/chat               - chat con streaming SSE
class RemoteTutorDatasource {
  final String _baseUrl;
  final ApiClient _apiClient;
  final SseClient _sseClient;

  RemoteTutorDatasource({
    required String baseUrl,
    required ApiClient apiClient,
    SseClient? sseClient,
  })  : _baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _apiClient = apiClient,
        _sseClient = sseClient ?? SseClient();

  String get _authToken {
    final token = _apiClient.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError(
        'No hay token de sesión. El usuario debe iniciar sesión antes de usar el tutor.',
      );
    }
    return token;
  }

  // ── POST /documents — subir PDF ──────────────────────────────────

  Future<RemoteDocument> uploadDocument(File pdfFile) async {
    final url = Uri.parse('$_baseUrl/api/v1/tutor/documents');
    final request = http.MultipartRequest('POST', url);

    request.headers['Authorization'] = 'Bearer $_authToken';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        pdfFile.path,
        filename: pdfFile.path.split(RegExp(r'[/\\]')).last,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 202) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      return RemoteDocument.fromJson(decoded);
    }

    throw _mapError(response, 'subir el PDF');
  }

  // ── GET /documents/{id} — consultar estado ───────────────────────

  Future<RemoteDocument> getDocumentStatus(String documentId) async {
    final url = Uri.parse('$_baseUrl/api/v1/tutor/documents/$documentId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_authToken'},
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      return RemoteDocument.fromJson(decoded);
    }

    throw _mapError(response, 'consultar el documento');
  }

  // ── POST /chat — streaming SSE ───────────────────────────────────

  /// Envía una pregunta y emite eventos del stream.
  Stream<RemoteChatEvent> chat({
    required String question,
    String? documentId,
    required List<ChatMessage> history,
  }) async* {
    final url = '$_baseUrl/api/v1/tutor/chat';

    final body = <String, dynamic>{
      'question': question,
      if (documentId != null) 'document_id': documentId,
      'history': history
          .where((m) => !m.isSystem && !m.isStreaming)
          .map((m) => {
        'role': m.role.name,
        'content': m.content,
      })
          .toList(),
    };

    debugPrint('🐛 documentId recibido: "$documentId" (${documentId.runtimeType})');
    debugPrint('🐛 BODY completo: ${json.encode(body)}');

    try {
      final events = _sseClient.post(
        url: url,
        body: body,
        headers: {'Authorization': 'Bearer $_authToken'},
      );

      await for (final event in events) {
        if (event.containsKey('token')) {
          yield RemoteTokenEvent(event['token'] as String);
        } else if (event['done'] == true) {
          final rawSources = (event['sources'] as List?) ?? [];
          final sources = rawSources
              .cast<Map<String, dynamic>>()
              .map(TutorSource.fromJson)
              .toList();
          yield RemoteDoneEvent(sources);
          return;
        } else if (event.containsKey('error')) {
          yield RemoteErrorEvent(event['error'] as String);
          return;
        }
      }
    } on SseException catch (e) {
      yield RemoteErrorEvent('Error de conexión: ${e.message}');
    } catch (e) {
      yield RemoteErrorEvent('Error inesperado: $e');
    }
  }

  Exception _mapError(http.Response response, String context) {
    String message = 'Error al $context (HTTP ${response.statusCode})';
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      } else if (decoded is Map && decoded['error'] != null) {
        message = decoded['error'].toString();
      }
    } catch (_) {}
    return Exception(message);
  }
}
