import '../entities/reading_progress.dart';

/// Los ViewModels dependen únicamente de esta abstracción.
abstract class ReaderRepository {
  /// Guarda o actualiza el progreso de lectura del usuario.
  Future<void> saveProgress(ReadingProgress progress);

  /// Recupera el progreso guardado para un libro específico.
  /// Retorna null si el usuario no ha comenzado a leer ese libro.
  Future<ReadingProgress?> getProgress(String bookId);
}