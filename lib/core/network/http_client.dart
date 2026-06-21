import 'dart:convert';
import 'package:http/http.dart' as http;

/// Excepciones personalizadas para manejar errores de red de forma limpia
class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Error en el servidor']);

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Error de conexión de red']);

  @override
  String toString() => message;
}

/// Cliente HTTP base para toda la aplicación
class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> get(String url, {Map<String, String>? headers}) async {
    try {
      final response = await _client.get(Uri.parse(url), headers: headers);
      return _handleResponse(response);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw NetworkException('Fallo la conexión con el servidor: $e');
    }
  }

  // Aquí agregarías post(), put(), delete() cuando lo requiera tu backend

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      print('DETALLE DEL ERROR DE GOOGLE: ${response.body}');
      throw ServerException(
        'Error ${response.statusCode}: No se pudo procesar la solicitud',
      );
    }
  }
}