import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';
import '../viewmodels/home_viewmodel.dart';
import '../components/book_card.dart';

/// Muestra el catálogo completo de libros en una lista con carga
/// perezosa (ListView.builder = el "LazyColumn" de Flutter): solo
/// construye las tarjetas que están cerca de la pantalla visible.
///
/// Además detecta cuándo el usuario llega al final de la lista y pide
/// más libros al [HomeViewModel] (que a su vez trae más de Gutendex),
/// así que el catálogo sigue creciendo mientras se hace scroll.
class AllBooksView extends StatefulWidget {
  final HomeViewModel viewModel;
  final void Function(Book) onBookTap;

  const AllBooksView({
    Key? key,
    required this.viewModel,
    required this.onBookTap,
  }) : super(key: key);

  @override
  State<AllBooksView> createState() => _AllBooksViewState();
}

class _AllBooksViewState extends State<AllBooksView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      widget.viewModel.loadNextPage('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final books = widget.viewModel.allBooks;
        final hasMore = widget.viewModel.hasMoreItems;

        return Scaffold(
          appBar: AppBar(
            title: Text('Todo el catálogo (${books.length})'),
          ),
          body: books.isEmpty
              ? const Center(child: Text('No hay libros en el catálogo.'))
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: books.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == books.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
              }

              final book = books[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: BookCard(
                  book: book,
                  onTap: () => widget.onBookTap(book),
                ),
              );
            },
          ),
        );
      },
    );
  }
}