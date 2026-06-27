class ReadingProgress {
  final String bookId;
  final int currentPage;
  final int totalPages;
  final double percentage;
  final DateTime lastReadAt;

  ReadingProgress({
    required this.bookId,
    required this.currentPage,
    required this.totalPages,
    required this.lastReadAt,
  }) : percentage = totalPages > 0 ? (currentPage / totalPages) * 100 : 0;

  ReadingProgress copyWith({
    int? currentPage,
    int? totalPages,
    DateTime? lastReadAt,
  }) {
    return ReadingProgress(
      bookId: bookId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }
}