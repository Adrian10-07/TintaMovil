import '../../domain/entities/reading_progress.dart';

/// Serialización JSON de [ReadingProgress] para la capa de datos.
class ReadingProgressModel {
  static ReadingProgress fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      bookId: json['book_id'] as String,
      currentPage: json['current_page'] as int,
      totalPages: json['total_pages'] as int,
      lastReadAt: DateTime.parse(json['last_read_at'] as String),
    );
  }

  static Map<String, dynamic> toJson(ReadingProgress progress) {
    return {
      'book_id': progress.bookId,
      'current_page': progress.currentPage,
      'total_pages': progress.totalPages,
      'last_read_at': progress.lastReadAt.toIso8601String(),
    };
  }
}