import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:tinta/core/ui/theme3material/theme.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../../core/presentation/components/tinta_background.dart';
import '../components/home_app_bar.dart';
import '../components/streak_card.dart';
import '../components/book_card.dart';
import '../../../../features/home/domain/entities/book.dart';
import '../../../../features/document_viewer/presentation/views/pdf_results_view.dart';
import 'all_books_view.dart';
import '../../../notifications/presentation/views/notifications_view.dart';
import '../../../../features/user/presentation/viewmodels/user_viewmodel.dart';
import '../components/currently_reading_book.dart';
import '../components/currently_reading_section.dart';
import '../../../../main.dart' show appRouteObserver;
import '../../../../core/presentation/utils/page_transitions.dart';

class HomeView extends StatefulWidget {
  final HomeViewModel viewModel;
  final String defaultQuery;

  /// Cuando es true, esta vista se está usando como pestaña dentro de
  /// [MainTabShell]: no dibuja su propio Scaffold ni barra inferior (esas
  /// las pone el shell), y no maneja su propia navegación de pestañas.
  final bool embedded;

  const HomeView({
    Key? key,
    required this.viewModel,
    required this.defaultQuery,
    this.embedded = false,
  }) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with RouteAware {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadInitialCatalog(widget.defaultQuery);
      _reloadUserData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Se llama cuando la ruta de arriba se cierra y Home vuelve a quedar
  /// visible (por ejemplo, al regresar de leer un libro). Refresca la
  /// racha y "Leyendo actualmente" sin importar cuántas pantallas se
  /// hayan apilado encima de Home.
  @override
  void didPopNext() {
    _reloadUserData();
  }

  void _reloadUserData() {
    final userId = context.read<UserViewModel>().profile?.id;
    if (userId != null) {
      widget.viewModel.loadStreak(userId);
      widget.viewModel.loadCurrentlyReading(userId);
      widget.viewModel.loadUnreadNotifications(userId);
    }
  }

  void _onNotificationTap() {
    final userId = context.read<UserViewModel>().profile?.id;
    if (userId == null) return;

    Navigator.push(
      context,
      fadeSlideRoute(NotificationsView(userId: userId)),
    ).then((_) {
      // Al regresar de la bandeja, refresca el conteo (ya se marcaron
      // como leídas al abrirla).
      widget.viewModel.loadUnreadNotifications(userId);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.viewModel.loadNextPage(widget.defaultQuery);
    }
  }

  void _onBookTap(Book book) {
    Navigator.pushNamed(context, '/book-detail', arguments: book);
  }

  void _onSeeAllTap() {
    Navigator.push(
      context,
      fadeSlideRoute(AllBooksView(
        viewModel: widget.viewModel,
        onBookTap: _onBookTap,
      )),
    );
  }

  /// Al tocar una tarjeta de "Leyendo actualmente", busca el libro
  /// correspondiente en el catálogo cargado y abre el lector directo en
  /// ese libro para continuar leyendo. Si es un PDF subido (no tiene
  /// lector), avisa que aún no se puede abrir.
  void _onCurrentlyReadingTap(CurrentlyReadingBook book) {
    // Los PDFs subidos guardan su ruta local como bookId con el prefijo
    // "upload:" (ver upload_book_viewmodel.dart). Si es uno de esos,
    // abrimos el visor de PDF simple en vez del lector de EPUB.
    if (book.bookId.startsWith('upload:')) {
      final path = book.bookId.substring('upload:'.length);
      final file = File(path);

      if (!file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ese archivo ya no está disponible en el dispositivo.')),
        );
        return;
      }

      Navigator.push(
        context,
        fadeSlideRoute(PdfResultsView(pdfFile: file)),
      );
      return;
    }

    final catalogBook = widget.viewModel.findBookById(book.bookId);

    if (catalogBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este documento aún no tiene un lector disponible.')),
      );
      return;
    }

    Navigator.pushNamed(context, '/reader', arguments: catalogBook);
  }

  Future<void> _onCurrentlyReadingLongPress(CurrentlyReadingBook book) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar de Leyendo actualmente'),
        content: Text('¿Quitar "${book.title}" de tu lista? Esto no borra tu progreso guardado en el libro, solo lo oculta de aquí.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    final userId = context.read<UserViewModel>().profile?.id;
    if (userId != null) {
      await widget.viewModel.removeFromCurrentlyReading(userId, book.bookId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = TintaBackground(
      blobs: [
        BlobConfig(
          top: -120, right: -80,
          color: colorScheme.primary, size: 320, opacity: 0.10,
        ),
        BlobConfig(
          top: 300, left: -60,
          color: MaterialTheme.warmGold, size: 220, opacity: 0.08,
        ),
      ],
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            HomeAppBar(
              hasNotifications: widget.viewModel.hasUnreadNotifications,
              onNotificationTap: _onNotificationTap,
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.viewModel,
                builder: (context, _) => _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );

    // Como pestaña del shell: sin Scaffold ni bottomNavigationBar propios
    // (eso ya lo pone MainTabShell).
    if (widget.embedded) return content;

    // Uso independiente (fuera del shell): sigue funcionando solo.
    return Scaffold(body: content);
  }

  Widget _buildBody() {
    final state = widget.viewModel.state;
    final books = widget.viewModel.books;

    if (state == HomeState.loadingInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state == HomeState.error && books.isEmpty) {
      return _ErrorState(
        message: widget.viewModel.errorMessage,
        onRetry: () => widget.viewModel.loadInitialCatalog(widget.defaultQuery),
      );
    }

    if (books.isEmpty) {
      return const _EmptyState();
    }

    return _CatalogContent(
      scrollController: _scrollController,
      books: books,
      hasMore: widget.viewModel.hasMoreItems,
      streakDays: widget.viewModel.streakDays,
      completedDayIndices: widget.viewModel.completedDayIndices,
      currentlyReading: widget.viewModel.currentlyReading,
      onBookTap: _onBookTap,
      onSeeAllTap: _onSeeAllTap,
      onCurrentlyReadingTap: _onCurrentlyReadingTap,
      onCurrentlyReadingLongPress: _onCurrentlyReadingLongPress,
    );
  }
}

class _CatalogContent extends StatelessWidget {
  final ScrollController scrollController;
  final List<Book> books;
  final bool hasMore;
  final int streakDays;
  final List<int> completedDayIndices;
  final List<CurrentlyReadingBook> currentlyReading;
  final void Function(Book) onBookTap;
  final VoidCallback onSeeAllTap;
  final void Function(CurrentlyReadingBook) onCurrentlyReadingTap;
  final void Function(CurrentlyReadingBook) onCurrentlyReadingLongPress;

  const _CatalogContent({
    required this.scrollController,
    required this.books,
    required this.hasMore,
    required this.streakDays,
    required this.completedDayIndices,
    required this.currentlyReading,
    required this.onBookTap,
    required this.onSeeAllTap,
    required this.onCurrentlyReadingTap,
    required this.onCurrentlyReadingLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: StreakCard(
              streakDays: streakDays,
              completedDayIndices: completedDayIndices,
            ),
          ),
        ),

        // Carrusel horizontal "Leyendo actualmente" — scroll lateral
        // independiente del scroll vertical de este CustomScrollView.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: CurrentlyReadingSection(
              books: currentlyReading,
              onSeeAllTap: () {
                // pendiente: navegar a vista de "todos los en progreso"
              },
              onBookTap: onCurrentlyReadingTap,
              onBookLongPress: onCurrentlyReadingLongPress,
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Explorar catálogo', style: textTheme.headlineSmall),
                InkWell(
                  onTap: onSeeAllTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'Ver todo',
                      style: textTheme.labelMedium
                          ?.copyWith(color: colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              if (index == books.length) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 6),
                child: BookCard(
                  book: books[index],
                  onTap: () => onBookTap(books[index]),
                ),
              );
            },
            childCount: books.length + (hasMore ? 1 : 0),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 56, color: colorScheme.primaryContainer),
          const SizedBox(height: 16),
          Text(
            message ?? 'Error al cargar catálogo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book_rounded,
              size: 56, color: colorScheme.primaryContainer),
          const SizedBox(height: 12),
          Text(
            'No se encontraron libros.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}