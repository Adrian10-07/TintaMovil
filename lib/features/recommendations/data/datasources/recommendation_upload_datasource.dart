import 'dart:io';
import 'package:http/http.dart' as http;

/// Excepción específica para errores al generar recomendaciones desde PDF.
class GenerateRecommendationsException implements Exception {
  final String message;
  GenerateRecommendationsException(this.message);
  @override
  String toString() => message;
}

/// DataSource que sube un PDF al servicio ML (Go) y dispara la generación
/// de recomendaciones para ese usuario.
///
/// Este servicio es DISTINTO al de Recomendaciones (Poyo): es tu servidor Go
/// standalone, el que corre `go run . -server`.
class RecommendationUploadDataSource {
  // ⚠️ CAMBIA esta URL por donde esté corriendo tu servidor Go.
  //
  // - Si lo corres en tu compu y pruebas en el EMULADOR de Android:
  //     'http://10.0.2.2:8090'
  // - Si lo corres en tu compu y pruebas en un celular FÍSICO en la misma
  //   red Wi-Fi:
  //     'http://TU_IP_LOCAL:8090'   (ej. http://192.168.1.50:8090)
  // - Si lo subes a Railway (recomendado para la entrega):
  //     'https://tu-servicio-ml.up.railway.app'
  static const String _baseUrl = 'https://tinta-recommendations-ml2-production.up.railway.app';

  /// Sube [pdfFile] y dispara la generación. [questions] son opcionales.
  /// Devuelve cuántas recomendaciones nuevas se generaron.
  Future<int> generateFromPdf({
    required String userId,
    required File pdfFile,
    List<String> questions = const [],
  }) async {
    final uri = Uri.parse('$_baseUrl/api/v1/recommendations/generate');
    final request = http.MultipartRequest('POST', uri);

    request.fields['user_id'] = userId;
    if (questions.isNotEmpty) {
      request.fields['questions'] = questions.join('|');
    }
    request.files.add(
      await http.MultipartFile.fromPath('book', pdfFile.path),
    );

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        // El backend responde: { "message": "...", "recomendaciones_nuevas": N }
        final match = RegExp(r'"recomendaciones_nuevas"\s*:\s*(\d+)')
            .firstMatch(response.body);
        return match != null ? int.parse(match.group(1)!) : 0;
      }

      // Intenta extraer el mensaje de error del backend: { "error": "..." }
      final errMatch = RegExp(r'"error"\s*:\s*"([^"]*)"').firstMatch(response.body);
      throw GenerateRecommendationsException(
        errMatch?.group(1) ?? 'Error ${response.statusCode} al generar recomendaciones',
      );
    } on GenerateRecommendationsException {
      rethrow;
    } catch (e) {
      throw GenerateRecommendationsException('Fallo la conexión: $e');
    }
  }
}