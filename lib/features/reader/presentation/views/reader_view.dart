import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import '../../../home/domain/entities/book.dart';
import '../../data/services/epub_download_service.dart';
import '../../data/services/reading_library_service.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../features/user/presentation/viewmodels/user_viewmodel.dart';
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

  int _totalPages = 0;
  int _lastSavedPage = -1;

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

      final documentFuture = EpubDocument.openFile(file);

      // epub_view no tiene paginación real; usamos el número de capítulos
      // como aproximación del total de "páginas" para el progreso.
      final epubBook = await documentFuture;
      _totalPages = epubBook.Chapters?.length ?? 0;

      final controller = EpubController(
        document: documentFuture,
      );

      if (mounted) {
        setState(() {
          _epubController = controller;
          _isLoading = false;
        });
      }

      // Guarda una entrada inicial (página 0) para que el libro aparezca
      // en "Leyendo actualmente" desde que se abre, no solo al avanzar
      // (onChapterChanged no se dispara con la sola apertura).
      debugPrint('[Reader] libro cargado: totalPages=$_totalPages');
      if (_totalPages > 0) {
        _lastSavedPage = 0;
        unawaited(_saveProgress(book, 0));
      } else {
        debugPrint('[Reader] totalPages es 0, NO se guarda progreso inicial');
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

  /// Se dispara cada que el usuario cambia de capítulo dentro del EpubView
  /// (es la unidad de granularidad más fina que expone epub_view — no hay
  /// paginación real en un lector de scroll continuo). La usamos como
  /// aproximación de "página" para el progreso.
  ///
  /// Nota: no se tipa explícitamente el parámetro `value` porque la clase
  /// que usa epub_view para este callback no se exporta como público desde
  /// el paquete; Dart infiere el tipo directamente desde la firma de
  /// EpubView.onChapterChanged.
  void _onChapterChanged(Book book, dynamic value) {
    int? pageNumber;
    try {
      // chapterNumber es el nombre real del campo en epub_view; lo usamos
      // como equivalente de "página" para efectos de nuestro progreso.
      pageNumber = value?.chapterNumber as int?;
    } catch (_) {
      pageNumber = null;
    }
    if (pageNumber == null || _totalPages == 0) return;
    if (pageNumber == _lastSavedPage) return;
    _lastSavedPage = pageNumber;

    _saveProgress(book, pageNumber);
  }

  Future<void> _saveProgress(Book book, int pageNumber) async {
    final userVm = sl<UserViewModel>();
    if (userVm.profile == null) {
      debugPrint('[Reader] perfil no cargado, pidiendo loadProfile()');
      await userVm.loadProfile();
    }
    final userId = userVm.profile?.id;
    if (userId == null) {
      debugPrint('[Reader] userId sigue siendo null, NO se guarda progreso');
      return;
    }

    debugPrint('[Reader] guardando progreso: userId=$userId bookId=${book.id} página=$pageNumber de $_totalPages');

    await ReadingLibraryService.upsert(
      userId,
      ReadingLibraryEntry(
        bookId: book.id,
        title: book.title,
        author: book.authors.isNotEmpty ? book.authors.first : 'Autor desconocido',
        currentPage: pageNumber,
        totalPages: _totalPages,
        lastReadAt: DateTime.now(),
      ),
    );

    debugPrint('[Reader] progreso guardado OK');
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

    return EpubView(
      controller: _epubController!,
      onChapterChanged: (value) => _onChapterChanged(book, value),
    );
  }
}