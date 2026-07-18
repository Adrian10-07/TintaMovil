import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:tinta/features/home/domain/entities/book.dart';

class EpubDownloadService {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  /// Devuelve el EPUB de [book], usando una copia guardada localmente si
  /// ya se descargó antes (permite leer libros ya abiertos sin conexión).
  Future<File> download(Book book) async {
    final file = await _localFile(book);

    if (await file.exists()) {
      return file;
    }

    try {
      return await _downloadFresh(book, file);
    } on SocketException {
      rethrow;
    }
  }

  Future<File> _localFile(Book book) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/epub_cache/book_${book.id}.epub');
  }

  Future<File> _downloadFresh(Book book, File destination) async {
    final client = http.Client();
    try {
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

      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(response.bodyBytes);
      return destination;
    } finally {
      client.close();
    }
  }

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