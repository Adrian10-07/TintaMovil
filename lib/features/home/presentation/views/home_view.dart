import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';
import '../viewmodels/home_viewmodel.dart';
import '../../../../core/presentation/components/tinta_background.dart';
import '../components/home_app_bar.dart';
import '../components/streak_card.dart';
import '../components/book_card.dart';
import '../components/tinta_bottom_nav.dart';
import '../../../../features/home/domain/entities/book.dart';

class HomeView extends StatefulWidget {
  final HomeViewModel viewModel;
  final String defaultQuery;

  const HomeView({
    Key? key,
    required this.viewModel,
    required this.defaultQuery,
  }) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scrollController = ScrollController();
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadInitialCatalog(widget.defaultQuery);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.viewModel.loadNextPage(widget.defaultQuery);
    }
  }

  void _onBookTap(Book book) {
    // Navega al detalle del libro pasando el libro como argumento
    Navigator.pushNamed(context, '/book-detail', arguments: book);
  }

  void _onNavTap(int index) {
    if (index == 4) {
      // Tab 'Yo' → navega a la pantalla de perfil
      Navigator.pushNamed(context, '/user');
      return;
    }
    setState(() => _selectedNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: TintaBackground(
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
                onNotificationTap: () {},
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
      ),
      bottomNavigationBar: TintaBottomNav(
        currentIndex: _selectedNavIndex,
        onTap: _onNavTap,
      ),
    );
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
      onBookTap: _onBookTap,
    );
  }
}

class _CatalogContent extends StatelessWidget {
  final ScrollController scrollController;
  final List<Book> books;
  final bool hasMore;
  final void Function(Book) onBookTap;

  const _CatalogContent({
    required this.scrollController,
    required this.books,
    required this.hasMore,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: StreakCard(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Explorar catálogo', style: textTheme.headlineSmall),
                Text(
                  'Ver todo',
                  style: textTheme.labelMedium
                      ?.copyWith(color: colorScheme.primary),
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