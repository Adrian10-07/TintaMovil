import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:tinta/features/home/domain/entities/book.dart';

/// Encapsula toda la lógica de descarga, caché y validación del EPUB.
/// Separado del widget para que ReaderView se mantenga enfocado en UI.
class EpubDownloadService {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  /// Devuelve el EPUB de [book], usando una copia guardada localmente si
  /// ya se descargó antes (permite leer libros ya abiertos sin conexión).
  /// Si no hay copia local, lo descarga; si la descarga falla pero existe
  /// una copia local previa, cae de vuelta a esa copia en lugar de fallar.
  ///
  /// Lanza [HttpException] o [SocketException] si algo falla y no hay
  /// ninguna copia local disponible como respaldo.
  Future<File> download(Book book) async {
    final file = await _localFile(book);

    if (await file.exists()) {
      // Ya lo teníamos descargado — no hace falta red, funciona offline.
      return file;
    }

    try {
      return await _downloadFresh(book, file);
    } on SocketException {
      // Sin conexión y sin copia local: no hay nada que mostrar.
      rethrow;
    }
  }

  Future<File> _localFile(Book book) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/epub_cache/book_${book.id}.epub');
  }

  /// Borra todos los EPUB guardados localmente (Perfil > Privacidad >
  /// "Borrar libros descargados"). La próxima vez que se abra cada libro,
  /// se vuelve a descargar (necesita conexión esa primera vez otra vez).
  static Future<void> clearCache() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/epub_cache');
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
  }

  /// Tamaño total del caché de EPUBs en MB, para mostrarlo en Privacidad.
  static Future<double> cacheSizeMb() async {
    final dir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${dir.path}/epub_cache');
    if (!await cacheDir.exists()) return 0.0;

    var totalBytes = 0;
    await for (final entity in cacheDir.list(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes / (1024 * 1024);
  }

  Future<File> _downloadFresh(Book book, File destination) async {
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

      await destination.parent.create(recursive: true);
      await destination.writeAsBytes(response.bodyBytes);
      return destination;
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