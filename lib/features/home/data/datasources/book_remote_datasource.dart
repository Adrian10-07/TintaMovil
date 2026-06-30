import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/curated_book_model.dart';
import '../../domain/entities/book.dart';

class BookRemoteDataSource {
  /// Carga el catálogo curado desde assets/data/curated_catalog.json
  /// Este archivo vive localmente en el proyecto Flutter — no requiere
  /// red ni depende de ninguna API externa de búsqueda. La descarga del
  /// EPUB real sí va a internet (a standardebooks.org), pero la lista
  /// de qué libros existen y sus metadatos los mantienes tú mismo.
  Future<List<Book>> fetchCatalog({String? category}) async {
    final jsonString =
    await rootBundle.loadString('assets/data/curated_catalog.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    final allBooks = CuratedBookModel.fromCatalogJson(jsonData);

    if (category == null || category == 'Todos') {
      return allBooks;
    }
    return allBooks.where((b) => b.category == category).toList();
  }
}