import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../home/domain/entities/book.dart';

/// Pantalla de lectura in-app.
///
/// Carga el visor de Google Books (webReaderLink) dentro de un WebView.
/// El usuario puede leer sin salir de la app.
///
/// Navegación:
/// ```dart
/// Navigator.pushNamed(context, '/reader', arguments: book);
/// ```
class ReaderView extends StatefulWidget {
  const ReaderView({Key? key}) : super(key: key);

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final book = ModalRoute.of(context)!.settings.arguments as Book;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress / 100);
          },
        ),
      )
      ..loadRequest(Uri.parse(book.webReaderLink!));
  }

  @override
  Widget build(BuildContext context) {
    final book = ModalRoute.of(context)!.settings.arguments as Book;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              book.authors.join(', '),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
        actions: [
          // Badge de tipo de acceso
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: book.isFullAccess
                  ? colorScheme.primaryContainer
                  : colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              book.accessLabel,
              style: textTheme.labelSmall?.copyWith(
                color: book.isFullAccess
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de progreso de carga
          if (_isLoading)
            LinearProgressIndicator(
              value: _progress > 0 ? _progress : null,
              minHeight: 3,
            ),

          // WebView con el visor de Google Books
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}