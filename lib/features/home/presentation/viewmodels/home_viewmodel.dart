import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

enum HomeState { initial, loadingInitial, success, error }

enum BookCategory {
  all('Todos'),
  study('Estudio'),
  science('Ciencia'),
  philosophy('Filosofía'),
  reading('Lectura');

  final String label;
  const BookCategory(this.label);
}

class HomeViewModel extends ChangeNotifier {
  final BookRepository _bookRepository;

  HomeViewModel(this._bookRepository);

  HomeState _state = HomeState.initial;
  HomeState get state => _state;

  List<Book> _books = [];
  List<Book> get books => List.unmodifiable(_books);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  BookCategory _selectedCategory = BookCategory.all;
  BookCategory get selectedCategory => _selectedCategory;

  // El catálogo curado es local y pequeño — no hay scroll infinito.
  bool get hasMoreItems => false;

  Future<void> selectCategory(BookCategory category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    await loadInitialCatalog('');
  }

  /// El parámetro query se mantiene por compatibilidad con la firma anterior,
  /// pero no se usa: el catálogo curado se filtra solo por categoría.
  Future<void> loadInitialCatalog(String query) async {
    _state = HomeState.loadingInitial;
    _errorMessage = null;
    notifyListeners();

    try {
      final categoryFilter = _selectedCategory == BookCategory.all
          ? null
          : _selectedCategory.label;

      _books = await _bookRepository.getBooksCatalog(category: categoryFilter);
      _state = HomeState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = HomeState.error;
    } finally {
      notifyListeners();
    }
  }

  /// No-op: el catálogo curado no pagina. Se mantiene para que home_view.dart
  /// no necesite cambios en su listener de scroll.
  Future<void> loadNextPage() async {}
}