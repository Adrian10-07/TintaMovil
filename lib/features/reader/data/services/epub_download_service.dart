import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:tinta/features/home/domain/entities/book.dart';

/// Encapsula toda la lógica de descarga y validación del EPUB.
/// Separado del widget para que ReaderView se mantenga enfocado en UI.
class EpubDownloadService {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  /// Descarga el EPUB del libro y lo guarda en almacenamiento temporal.
  /// Lanza [HttpException] o [SocketException] si algo falla, con
  /// mensajes detallados para depuración.
  Future<File> download(Book book) async {
    final client = http.Client();
    try {
      // Standard Ebooks distingue un clic real de un acceso directo
      // mediante ?source=download. Sin ese parámetro, el servidor
      // sirve una página de cortesía en vez del binario.
      final downloadUri = Uri.parse(book.epubUrl).replace(
        queryParameters: {'source': 'download'},
      );

      final request = http.Request('GET', downloadUri)
        ..headers['Accept'] = '*/*'
        ..headers['Referer'] = book.pageUrl
        ..headers['User-Agent'] = _userAgent
        ..followRedirects = true
        ..maxRedirects = 5;

      final streamedResponse =
      await client.send(request).timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw HttpException(
          'Código ${response.statusCode} al descargar $downloadUri',
        );
      }

      _validateIsEpub(response);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/book_${book.id}.epub');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } finally {
      client.close();
    }
  }

  /// Un EPUB es un ZIP; todo ZIP empieza con los bytes mágicos 'PK'.
  /// Si el servidor devolvió HTML (error, bloqueo, página de cortesía),
  /// lanzamos un error claro con preview del contenido recibido.
  void _validateIsEpub(http.Response response) {
    final bytes = response.bodyBytes;
    final isValidZip =
        bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;

    if (!isValidZip) {
      final preview = utf8.decode(
        bytes.take(300).toList(),
        allowMalformed: true,
      );
      throw HttpException(
        'El servidor no devolvió un EPUB válido.\n'
            'URL final tras redirects: ${response.request?.url}\n'
            'Content-Type: ${response.headers['content-type']}\n'
            'Respuesta (primeros 300 caracteres):\n$preview',
      );
    }
  }
}