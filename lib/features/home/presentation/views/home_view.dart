import 'package:flutter/material.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeView extends StatefulWidget {
  final HomeViewModel viewModel;
  final String defaultQuery; // Ej: "Flutter" o "Software Engineering"

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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Disparamos la carga inicial al montar el widget de forma segura
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Si el usuario está a 200px o menos del final, pedimos la siguiente página
      widget.viewModel.loadNextPage(widget.defaultQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo Tinta')),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final state = widget.viewModel.state;
          final books = widget.viewModel.books;

          if (state == HomeState.loadingInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state == HomeState.error && books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.viewModel.errorMessage ?? 'Error al cargar catálogo'),
                  ElevatedButton(
                    onPressed: () => widget.viewModel.loadInitialCatalog(widget.defaultQuery),
                    child: const Text('Reintentar'),
                  )
                ],
              ),
            );
          }

          if (books.isEmpty) {
            return const Center(child: Text('No se encontraron libros disponibles.'));
          }

          // Catálogo en formato lista listo para aplicar estilos
          return ListView.builder(
            controller: _scrollController,
            itemCount: books.length + (widget.viewModel.hasMoreItems ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == books.length) {
                // Indicador de carga inferior para la paginación activa
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final book = books[index];
              return ListTile(
                leading: book.thumbnailUrl != null
                    ? Image.network(book.thumbnailUrl!, width: 50, fit: BoxFit.cover)
                    : const Icon(Icons.book), // Placeholder estructural
                title: Text(book.title),
                subtitle: Text(book.authors.join(', ')),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Navegar al detalle del libro (Feature de Lectura / Estudio IA)
                },
              );
            },
          );
        },
      ),
    );
  }
}