import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../data/services/streak_service.dart';

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

  // ── Racha de lectura ────────────────────────────────────────────────────
  int _streakDays = 0;
  int get streakDays => _streakDays;

  List<int> _completedDayIndices = const [];
  List<int> get completedDayIndices => _completedDayIndices;

  /// Solo lee el estado guardado (no cuenta un nuevo día). Llamar al abrir
  /// Home para pintar la tarjeta con el valor real.
  Future<void> loadStreak(String userId) async {
    final result = await StreakService.getCurrent(userId);
    _streakDays = result.streakDays;
    _completedDayIndices = result.completedDayIndices;
    notifyListeners();
  }

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


  Future<void> loadNextPage(String defaultQuery) async {}
}