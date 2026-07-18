import 'package:flutter/material.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../data/services/streak_service.dart';
import '../../../reader/data/services/reading_library_service.dart';
import '../components/currently_reading_book.dart';
import '../../../notifications/data/services/notification_service.dart';

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
  // filtro tenga aplicado la vista de "Explorar catálogo".
  List<Book> _allBooks = [];
  List<Book> get allBooks => List.unmodifiable(_allBooks);

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

  // ── Scroll infinito (Gutendex) ────────────────────────────────────────
  // El catálogo curado (assets/data/curated_catalog.json) es fijo y
  // pequeño. Al llegar al final, se piden más libros de Gutendex
  // (Project Gutenberg) para que la lista siga creciendo. Solo aplica
  // cuando no hay filtro de categoría activo, porque los libros de
  // Gutendex no encajan en las categorías curadas a mano.
  String? _nextGutendexPageUrl;
  bool _gutendexStarted = false;
  bool _isLoadingMore = false;

  bool get hasMoreItems {
    if (_selectedCategory != BookCategory.all) return false;
    if (!_gutendexStarted) return true; // aún no hemos ni empezado a pedir
    return _nextGutendexPageUrl != null;
  }

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

  // ── Leyendo actualmente ─────────────────────────────────────────────────
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
      // Color/ícono determinísticos según el bookId, para que cada libro
      // siempre se vea igual sin depender de datos que no tenemos (portada).
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

  /// Quita un libro de "Leyendo actualmente" manualmente (long-press en
  /// la tarjeta) y refresca la lista.
  Future<void> removeFromCurrentlyReading(String userId, String bookId) async {
    await ReadingLibraryService.remove(userId, bookId);
    await loadCurrentlyReading(userId);
  }

  // ── Notificaciones ─────────────────────────────────────────────────────
  int _unreadNotifications = 0;
  int get unreadNotifications => _unreadNotifications;
  bool get hasUnreadNotifications => _unreadNotifications > 0;

  Future<void> loadUnreadNotifications(String userId) async {
    _unreadNotifications = await NotificationService.getUnreadCount(userId);
    notifyListeners();
  }

  Future<void> selectCategory(BookCategory category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    // Cambiar de categoría reinicia la paginación de Gutendex — no tiene
    // sentido seguir donde íbamos si ahora estamos viendo otro filtro.
    _nextGutendexPageUrl = null;
    _gutendexStarted = false;
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

      // Mantener también una copia sin filtrar, para poder encontrar
      // cualquier libro por id sin depender del filtro activo.
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

  /// Pide la siguiente "página" del catálogo. La primera vez que se llega
  /// al final de la lista curada, empieza a pedir libros de Gutendex; las
  /// siguientes veces sigue con la URL de paginación que Gutendex regresa.
  Future<void> loadNextPage(String defaultQuery) async {
    if (_isLoadingMore) return;
    if (!hasMoreItems) return;
    if (_selectedCategory != BookCategory.all) return;

    _isLoadingMore = true;
    try {
      final page = await _bookRepository.fetchMoreBooks(
        pageUrl: _gutendexStarted ? _nextGutendexPageUrl : null,
      );

      _gutendexStarted = true;
      _nextGutendexPageUrl = page.nextPageUrl;

      // Evita duplicados si por lo que sea la misma página se pide dos
      // veces (por ejemplo, si el scroll dispara el listener repetido).
      final existingIds = _books.map((b) => b.id).toSet();
      final nuevos = page.books.where((b) => !existingIds.contains(b.id));

      _books = [..._books, ...nuevos];
      _allBooks = [..._allBooks, ...nuevos];
    } catch (e) {
      debugPrint('[Home] loadNextPage falló: $e');
      // No cambiamos _state a error aquí — el catálogo inicial ya cargó
      // bien, solo falló traer más. El usuario simplemente deja de ver
      // más libros nuevos al hacer scroll; puede reintentar más tarde.
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}