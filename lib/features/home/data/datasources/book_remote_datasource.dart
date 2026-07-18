import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../models/curated_book_model.dart';
import '../models/google_book_model.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/gutendex_page.dart';

class BookRemoteDataSource {
  static const String _gutendexFirstPageUrl =
      'https://gutendex.com/books/?languages=en,es';

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

  /// Trae más libros desde Gutendex (Project Gutenberg) para extender el
  /// catálogo curado cuando el usuario llega al final de la lista.
  ///
  /// [pageUrl] es la URL de la siguiente página, tal como la regresa la
  /// API en su campo "next". Si es null, se pide la primera página.
  Future<GutendexPage> fetchMoreBooks({String? pageUrl}) async {
    final uri = Uri.parse(pageUrl ?? _gutendexFirstPageUrl);
    final response = await http.get(uri).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Gutendex respondió ${response.statusCode}');
    }

    final Map<String, dynamic> jsonData = json.decode(response.body);
    return GutendexBookModel.parsePage(jsonData);
  }
}