import 'package:flutter/material.dart';

class CurrentlyReadingBook {
  final String bookId;
  final String title;
  final String author;
  final int currentPage;
  final int totalPages;
  final double progress; // 0.0 - 1.0
  final IconData icon;
  final Color accentColor;

  const CurrentlyReadingBook({
    required this.bookId,
    required this.title,
    required this.author,
    required this.currentPage,
    required this.totalPages,
    required this.progress,
    required this.icon,
    required this.accentColor,
  });

  int get percent => (progress * 100).round();
}