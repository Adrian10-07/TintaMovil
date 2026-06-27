import 'package:flutter/foundation.dart';
import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reader_repository.dart';
import '../../../../features/home/domain/entities/book.dart';

enum ReaderState { initial, loading, ready, saving, error }

/// ViewModel para la pantalla de lectura de un libro.
///
/// Responsabilidades:
/// - Exponer el libro activo al UI
/// - Cargar y persistir el progreso de lectura
/// - Controlar navegación de páginas
class ReaderViewModel extends ChangeNotifier {
  final ReaderRepository _readerRepository;

  ReaderViewModel(this._readerRepository);

  // ── Estado ───────────────────────────────────────────────────
  ReaderState _state = ReaderState.initial;
  ReaderState get state => _state;

  Book? _book;
  Book? get book => _book;

  ReadingProgress? _progress;
  ReadingProgress? get progress => _progress;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  // totalPages es una estimación UI hasta que la API lo confirme
  int _totalPages = 100;
  int get totalPages => _totalPages;

  double get readingPercentage =>
      _totalPages > 0 ? (_currentPage / _totalPages).clamp(0.0, 1.0) : 0.0;

  bool _isBookmarked = false;
  bool get isBookmarked => _isBookmarked;

  // ── Inicialización ───────────────────────────────────────────

  /// Inicializa el lector con el libro seleccionado y carga el progreso previo.
  Future<void> initReader(Book book) async {
    _book = book;
    _setState(ReaderState.loading);

    try {
      final saved = await _readerRepository.getProgress(book.id);
      if (saved != null) {
        _progress = saved;
        _currentPage = saved.currentPage;
        _totalPages = saved.totalPages > 0 ? saved.totalPages : _totalPages;
      }
      _setState(ReaderState.ready);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ReaderState.error);
    }
  }

  // ── Navegación ───────────────────────────────────────────────

  void goToNextPage() {
    if (_currentPage < _totalPages) {
      _currentPage++;
      notifyListeners();
      _autoSaveProgress();
    }
  }

  void goToPreviousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      notifyListeners();
      _autoSaveProgress();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _currentPage = page;
      notifyListeners();
      _autoSaveProgress();
    }
  }

  // ── Bookmark ────────────────────────────────────────────────

  void toggleBookmark() {
    _isBookmarked = !_isBookmarked;
    notifyListeners();
  }

  // ── Persistencia ────────────────────────────────────────────

  Future<void> saveProgress() async {
    if (_book == null) return;
    _setState(ReaderState.saving);
    try {
      final newProgress = ReadingProgress(
        bookId: _book!.id,
        currentPage: _currentPage,
        totalPages: _totalPages,
        lastReadAt: DateTime.now(),
      );
      await _readerRepository.saveProgress(newProgress);
      _progress = newProgress;
      _setState(ReaderState.ready);
    } catch (e) {
      // Error silencioso en guardado automático — no interrumpe la lectura
      _setState(ReaderState.ready);
    }
  }

  /// Guarda el progreso automáticamente cada 5 páginas.
  void _autoSaveProgress() {
    if (_currentPage % 5 == 0) {
      saveProgress();
    }
  }

  // ── Helper ──────────────────────────────────────────────────

  void _setState(ReaderState newState) {
    _state = newState;
    notifyListeners();
  }
}