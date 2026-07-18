import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../data/services/streak_service.dart';
import '../../../reader/data/services/reading_library_service.dart';
import '../components/currently_reading_book.dart';

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

  // Catálogo completo SIN filtrar por categoría — se usa para encontrar
  // un libro por id (ej. desde "Leyendo actualmente") sin importar qué
  // filtro tenga aplicado la vista de "Explorar catálogo" en ese momento.
  List<Book> _allBooks = [];

  Book? findBookById(String id) {
    for (final b in _allBooks) {
      if (b.id == id) return b;
    }
    return null;
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  BookCategory _selectedCategory = BookCategory.all;
  BookCategory get selectedCategory => _selectedCategory;

  bool get hasMoreItems => false;

  int _streakDays = 0;
  int get streakDays => _streakDays;

  List<int> _completedDayIndices = const [];
  List<int> get completedDayIndices => _completedDayIndices;

  Future<void> loadStreak(String userId) async {
    final result = await StreakService.getCurrent(userId);
    _streakDays = result.streakDays;
    _completedDayIndices = result.completedDayIndices;
    notifyListeners();
  }

  List<CurrentlyReadingBook> _currentlyReading = const [];
  List<CurrentlyReadingBook> get currentlyReading => _currentlyReading;

  static const List<Color> _accentPalette = [
    Color(0xFF1C6B50),
    Color(0xFF6B5FD8),
    Color(0xFFE8924A),
    Color(0xFFFF7E7E),
    Color(0xFF2E7DAF),
  ];

  static const List<IconData> _iconPalette = [
    Icons.menu_book_rounded,
    Icons.auto_stories_rounded,
    Icons.bolt_rounded,
    Icons.nightlight_round,
    Icons.psychology_alt_rounded,
  ];

  Future<void> loadCurrentlyReading(String userId) async {
    final entries = await ReadingLibraryService.getInProgress(userId);
    debugPrint('[Home] loadCurrentlyReading userId=$userId → ${entries.length} libros encontrados');

    _currentlyReading = entries.map((e) {
      final paletteIndex = e.bookId.hashCode.abs() % _accentPalette.length;
      return CurrentlyReadingBook(
        bookId: e.bookId,
        title: e.title,
        author: e.author,
        currentPage: e.currentPage,
        totalPages: e.totalPages,
        progress: e.progress,
        icon: _iconPalette[paletteIndex],
        accentColor: _accentPalette[paletteIndex],
      );
    }).toList();

    notifyListeners();
  }

  Future<void> removeFromCurrentlyReading(String userId, String bookId) async {
    await ReadingLibraryService.remove(userId, bookId);
    await loadCurrentlyReading(userId);
  }

  Future<void> selectCategory(BookCategory category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    await loadInitialCatalog('');
  }

  Future<void> loadInitialCatalog(String query) async {
    _state = HomeState.loadingInitial;
    _errorMessage = null;
    notifyListeners();

    try {
      final categoryFilter = _selectedCategory == BookCategory.all
          ? null
          : _selectedCategory.label;

      _books = await _bookRepository.getBooksCatalog(category: categoryFilter);

      if (categoryFilter == null) {
        _allBooks = _books;
      } else if (_allBooks.isEmpty) {
        _allBooks = await _bookRepository.getBooksCatalog(category: null);
      }

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