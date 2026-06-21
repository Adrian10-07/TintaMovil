import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

enum HomeState { initial, loadingInitial, success, loadingMore, error }

class HomeViewModel extends ChangeNotifier {
  final BookRepository _bookRepository;

  HomeViewModel(this._bookRepository);

  HomeState _state = HomeState.initial;
  HomeState get state => _state;

  final List<Book> _books = [];
  List<Book> get books => List.unmodifiable(_books);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentIndex = 0;
  final int _pageSize = 20;
  bool _hasMoreItems = true;
  bool get hasMoreItems => _hasMoreItems;

  /// Carga inicial del catálogo de libros
  Future<void> loadInitialCatalog(String query) async {
    if (_state == HomeState.loadingInitial) return;

    _state = HomeState.loadingInitial;
    _errorMessage = null;
    _books.clear();
    _currentIndex = 0;
    _hasMoreItems = true;
    notifyListeners();

    await _fetchBooks(query);
  }

  /// Carga la siguiente página para el scroll infinito
  Future<void> loadNextPage(String query) async {
    if (_state == HomeState.loadingMore || !_hasMoreItems) return;

    _state = HomeState.loadingMore;
    notifyListeners();

    await _fetchBooks(query);
  }

  Future<void> _fetchBooks(String query) async {
    try {
      final newBooks = await _bookRepository.getBooksCatalog(
        query: query,
        startIndex: _currentIndex,
        maxResults: _pageSize,
      );

      if (newBooks.length < _pageSize) {
        _hasMoreItems = false;
      }

      _books.addAll(newBooks);
      _currentIndex += newBooks.length;
      _state = HomeState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = _books.isEmpty ? HomeState.error : HomeState.success; // Si ya había libros, no rompemos la pantalla
    } finally {
      notifyListeners();
    }
  }
}