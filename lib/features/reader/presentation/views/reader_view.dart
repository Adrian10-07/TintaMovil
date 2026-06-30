import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../home/domain/entities/book.dart';

class ReaderView extends StatefulWidget {
  const ReaderView({Key? key}) : super(key: key);

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  EpubController? _epubController;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final book = ModalRoute.of(context)!.settings.arguments as Book;
    if (_epubController == null) {
      _loadEpub(book);
    }
  }

  Future<void> _loadEpub(Book book) async {
    try {
      final file = await _downloadEpub(book);

      final controller = EpubController(
        document: EpubDocument.openFile(file),
      );

      if (mounted) {
        setState(() {
          _epubController = controller;
          _isLoading = false;
        });
      }
    } on SocketException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo conectar con standardebooks.org.\n'
              'Verifica tu conexión a internet.\n($e)';
          _isLoading = false;
        });
      }
    } on HttpException catch (e) {
      if (mounted) {
        setState(() {
          _error = 'El servidor rechazó la descarga: $e';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudo cargar el libro: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<File> _downloadEpub(Book book) async {
    final client = http.Client();
    try {
      // CLAVE: Standard Ebooks distingue un clic real de un acceso directo
      // a la URL mediante el query parameter ?source=download. Sin él,
      // el servidor sirve la página de cortesía "Your Download Has
      // Started!" en vez del binario, sin importar qué headers se manden.
      final downloadUri = Uri.parse(book.epubUrl).replace(
        queryParameters: {'source': 'download'},
      );

      final request = http.Request('GET', downloadUri)
        ..headers['Accept'] = '*/*'
        ..headers['Referer'] = book.pageUrl
        ..headers['User-Agent'] =
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36'
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

      // VALIDACIÓN: un EPUB es un ZIP, todo ZIP empieza con los bytes
      // mágicos 'PK' (0x50 0x4B). Si esto falla, el servidor no mandó
      // el binario real — mostramos qué devolvió en su lugar.
      final bytes = response.bodyBytes;
      final isValidZip = bytes.length > 4 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4B;

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

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/book_${book.id}.epub');
      await file.writeAsBytes(bytes);
      return file;
    } finally {
      client.close();
    }
  }

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = ModalRoute.of(context)!.settings.arguments as Book;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.title,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(book.authors.join(', '),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.55),
                )),
          ],
        ),
      ),
      body: _buildBody(colorScheme, book),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, Book book) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Descargando libro...',
                style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.55))),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 48, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      _loadEpub(book);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return EpubView(controller: _epubController!);
  }
}