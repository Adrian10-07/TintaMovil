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
import '../components/translated_chapter_sheet.dart';
import '../../../tutorAI/presentation/views/tutor_chat_sheet.dart';
import '../../../recommendations/presentation/views/recommendations_view.dart';
import '../../../home/data/services/streak_service.dart';
import '../../../achievements/data/services/achievement_service.dart';
import 'package:tinta/core/network/connectivity_checker.dart';
import '../../../tutorAI/presentation/views/remote_tutor_chat_sheet.dart';

class ReaderView extends StatefulWidget {
  const ReaderView({Key? key}) : super(key: key);

  @override
  State<ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<ReaderView> {
  final EpubDownloadService _downloadService = EpubDownloadService();
  final _connectivityChecker = ConnectivityChecker();

  EpubController? _epubController;
  bool _isLoading = true;
  String? _error;

  bool _hasStartedLoading = false;

  int _totalPages = 0;
  int _lastSavedPage = -1;
  int _currentChapterIndex = 0;
  List<dynamic> _chapters = const [];
  bool _streakRegisteredThisSession = false;

  void _showLoadingSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _openLocalEpubChat(Book book) {
    // Los capítulos ya están en memoria (_chapters, cargados en _loadEpub).
    // Se extrae el HTML de cada uno para indexarlo con TF-IDF en memoria.
    final htmlContents = <String>[];
    for (final chapter in _chapters) {
      try {
        final html = chapter.HtmlContent as String?;
        if (html != null && html.isNotEmpty) htmlContents.add(html);
      } catch (_) {
        // Si el campo no existe en esta versión de epub_view, se omite
        // ese capítulo en vez de tronar todo el chat.
      }
    }

    TutorChatSheet.show(
      context,
      documentContext: book.title,
      epubChapterHtmlContents: htmlContents,
    );
  }

  void _openRemoteGeneralChat(Book book) {
    // Sin document_id: chat general contra el backend (sin RAG real del
    // EPUB, ya que el backend solo indexa PDF). Si falla por conexión,
    // el botón de la propia sheet permite cambiar a modo local.
    RemoteTutorChatSheet.show(
      context,
      documentContext: book.title,
      onSwitchToOffline: () {
        Navigator.of(context).pop(); // cierra el sheet remoto
        _openLocalEpubChat(book);
      },
    );
  }

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

      // --- CAMBIO PRINCIPAL PARA COMPATIBILIDAD WEB / CHROME ---
      // En lugar de pasar 'file' a EpubDocument.openFile(file), leemos
      // los bytes para evitar el conflicto de clases 'File' de dart:io
      // y universal_file al compilar para la web.
      final fileBytes = await file.readAsBytes();
      final documentFuture = EpubDocument.openData(fileBytes);
      // ---------------------------------------------------------

      // Se necesita el total de capítulos para calcular el % de progreso,
      // y la lista completa para poder traducir el capítulo actual.
      final epubBook = await documentFuture;
      _chapters = epubBook.Chapters ?? [];
      _totalPages = _chapters.length;

      final controller = EpubController(
        document: documentFuture,
      );

      if (mounted) {
        setState(() {
          _epubController = controller;
          _isLoading = false;
        });
      }

      // Guarda una entrada inicial (capítulo 0) para que el libro aparezca
      // en "Leyendo actualmente" desde que se abre, no solo al cambiar de
      // capítulo (onChapterChanged no se dispara con la sola apertura).
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
    _currentChapterIndex = pageNumber;
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

    debugPrint('[Reader] guardando progreso: userId=$userId bookId=${book.id} capítulo=$pageNumber de $_totalPages');

    final entry = ReadingLibraryEntry(
      bookId: book.id,
      title: book.title,
      author: book.authors.isNotEmpty ? book.authors.first : 'Autor desconocido',
      currentPage: pageNumber,
      totalPages: _totalPages,
      lastReadAt: DateTime.now(),
    );

    await ReadingLibraryService.upsert(userId, entry);

    debugPrint('[Reader] progreso guardado OK');

    // La racha de lectura ahora se cuenta AQUÍ (al leer de verdad), no al
    // iniciar sesión. Solo se registra una vez por sesión de lectura para
    // no pegarle a SharedPreferences en cada cambio de capítulo.
    if (!_streakRegisteredThisSession) {
      _streakRegisteredThisSession = true;
      await StreakService.registerVisit(userId);
    }

    // Si el libro llegó a >=98%, cuenta como terminado para los logros
    // de "libros terminados".
    if (entry.progress >= 0.98) {
      final indexed = await ReadingLibraryService.getAllIndexed(userId);
      final finishedCount =
          indexed.values.where((e) => e.progress >= 0.98).length;
      await AchievementService.checkBooksFinished(userId, finishedCount);
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _isLoading = false;
    });
  }

  /// Abre el panel de traducción del capítulo que se está leyendo ahora
  /// mismo. Solo tiene sentido para libros de dominio público (todo el
  /// catálogo de Tinta lo es), ya que traduce el texto completo.
  void _onTranslateTap(Book book) {
    if (_chapters.isEmpty || _currentChapterIndex >= _chapters.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Espera a que termine de cargar el capítulo.')),
      );
      return;
    }

    final chapter = _chapters[_currentChapterIndex];
    String html = '';
    String title = '';
    try {
      html = (chapter.HtmlContent as String?) ?? '';
      title = (chapter.Title as String?)?.trim().replaceAll('\n', '') ?? '';
    } catch (_) {
      // Si el campo no existe con ese nombre exacto en esta versión del
      // paquete, se cae aquí — mejor avisar claro que tronar.
    }

    if (html.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el contenido de este capítulo para traducir.')),
      );
      return;
    }

    TranslatedChapterSheet.show(context, chapterTitle: title, chapterHtml: html);
  }

  void _onTutorChatTap(Book book)  {
    final htmlContents = <String>[];
    for (final chapter in _chapters) {
      try {
        final html = chapter.HtmlContent as String?;
        if (html != null && html.isNotEmpty) htmlContents.add(html);
      } catch (_) {
        // Si el campo no existe en esta versión de epub_view, se omite
        // ese capítulo en vez de tronar todo el chat.
      }
    }

    TutorChatSheet.show(
      context,
      documentContext: book.title,
      epubChapterHtmlContents: htmlContents,
    );
  }

  void _onRecommendationsTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RecommendationsView()),
    );
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
      appBar: ReaderAppBar(
        book: book,
        controller: _epubController,
        actions: _epubController == null
            ? null
            : [
          IconButton(
            tooltip: 'Traducir capítulo al español',
            icon: const Icon(Icons.translate_rounded),
            onPressed: () => _onTranslateTap(book),
          ),
          IconButton(
            tooltip: 'Pregunta a Tinta AI',
            icon: const Icon(Icons.auto_awesome_rounded),
            onPressed: () => _onTutorChatTap(book),
          ),
        ],
      ),
      body: SafeArea(top: false, child: _buildBody(book)),
      floatingActionButton: _epubController == null
          ? null
          : FloatingActionButton.extended(
        onPressed: _onRecommendationsTap,
        icon: const Icon(Icons.menu_book_rounded),
        label: const Text('Te puede interesar'),
      ),
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