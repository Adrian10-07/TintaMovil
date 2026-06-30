import 'dart:io';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import '../../../home/domain/entities/book.dart';
import '../../data/services/epub_download_service.dart';
import '../components/reader_app_bar.dart';
import '../components/reader_loading_state.dart';
import '../components/reader_error_state.dart';

class ReaderView extends StatefulWidget {
  const ReaderView({Key? key}) : super(key: key);

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  final EpubDownloadService _downloadService = EpubDownloadService();

  EpubController? _epubController;
  bool _isLoading = true;
  String? _error;

  bool _hasStartedLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStartedLoading) {
      _hasStartedLoading = true;
      final book = ModalRoute.of(context)!.settings.arguments as Book;
      _loadEpub(book);
    }
  }

  Future<void> _loadEpub(Book book) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final file = await _downloadService.download(book);

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
      _setError(
        'No se pudo conectar con standardebooks.org.\n'
            'Verifica tu conexión a internet.\n($e)',
      );
    } on HttpException catch (e) {
      _setError('El servidor rechazó la descarga: $e');
    } catch (e) {
      _setError('No se pudo cargar el libro: $e');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = ModalRoute.of(context)!.settings.arguments as Book;

    return Scaffold(
      appBar: ReaderAppBar(book: book, controller: _epubController),
      body: _buildBody(book),
    );
  }

  Widget _buildBody(Book book) {
    if (_isLoading) {
      return ReaderLoadingState(book: book);
    }

    if (_error != null) {
      return ReaderErrorState(
        errorMessage: _error!,
        onBack: () => Navigator.pop(context),
        onRetry: () => _loadEpub(book),
      );
    }

    return EpubView(controller: _epubController!);
  }
}