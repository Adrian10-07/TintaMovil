import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// Excepciones tipadas
// Coinciden con el ErrorBody del backend Go:
//   { "error": "message", "code": "CODE" }
// ─────────────────────────────────────────────────────────────────────────────

class ApiException implements Exception {
  final String message;
  final String? code;
  final int statusCode;
  ApiException(this.message, {this.code, this.statusCode = 500});

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'No autorizado'])
      : super(message, code: 'UNAUTHORIZED', statusCode: 401);
}

class ValidationException extends ApiException {
  ValidationException(String message)
      : super(message, code: 'VALIDATION_ERROR', statusCode: 400);
}

class ConflictException extends ApiException {
  ConflictException(String message)
      : super(message, code: 'EMAIL_EXISTS', statusCode: 409);
}

class NetworkException extends ApiException {
  NetworkException([String message = 'Error de conexión de red'])
      : super(message, code: 'NETWORK_ERROR', statusCode: 0);
}

// ─────────────────────────────────────────────────────────────────────────────
// ApiClient — Cliente HTTP centralizado
// ─────────────────────────────────────────────────────────────────────────────

class ApiClient {
  final http.Client _client;

  /// access_token JWT inyectado tras login.
  String? _accessToken;

  /// refresh_token para renovar la sesión.
  String? _refreshToken;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  // ── Token management ────────────────────────────────────────────────────

  void setTokens({required String accessToken, required String refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _accessToken != null;

  // ── Headers ─────────────────────────────────────────────────────────────

  Map<String, String> get _baseHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> get _authHeaders => {
    ..._baseHeaders,
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  // ── HTTP methods ────────────────────────────────────────────────────────

  Future<dynamic> get(String url, {bool auth = false}) async {
    try {
      final response = await _client.get(
        Uri.parse(url),
        headers: auth ? _authHeaders : _baseHeaders,
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('Fallo la conexión: $e');
    }
  }

  Future<dynamic> post(String url, {
    required Map<String, dynamic> body,
    bool auth = false,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: auth ? _authHeaders : _baseHeaders,
        body: json.encode(body),
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('Fallo la conexión: $e');
    }
  }

  Future<dynamic> patch(String url, {
    required Map<String, dynamic> body,
    bool auth = true,
  }) async {
    try {
      final response = await _client.patch(
        Uri.parse(url),
        headers: auth ? _authHeaders : _baseHeaders,
        body: json.encode(body),
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('Fallo la conexión: $e');
    }
  }

  Future<dynamic> delete(String url, {bool auth = true}) async {
    try {
      final response = await _client.delete(
        Uri.parse(url),
        headers: auth ? _authHeaders : _baseHeaders,
      );
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw NetworkException('Fallo la conexión: $e');
    }
  }

  // ── Response handling ───────────────────────────────────────────────────
  // El backend Tinta responde:
  //   Éxito: JSON directo (sin wrapper {data:...})
  //   Error: { "error": "message", "code": "CODE" }
  //   204:   sin body

  dynamic _handleResponse(http.Response response) {
    // 204 No Content
    if (response.statusCode == 204) return null;

    // Éxito (200, 201)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    // Errores — parsear el ErrorBody del backend
    String errorMessage = 'Error ${response.statusCode}';
    String? errorCode;

    try {
      final errorBody = json.decode(response.body);
      errorMessage = errorBody['error'] ?? errorMessage;
      errorCode = errorBody['code'];
    } catch (_) {}

    switch (response.statusCode) {
      case 401:
        throw UnauthorizedException(errorMessage);
      case 400:
        throw ValidationException(errorMessage);
      case 409:
        throw ConflictException(errorMessage);
      default:
        throw ApiException(
          errorMessage,
          code: errorCode,
          statusCode: response.statusCode,
        );
    }
  }
}