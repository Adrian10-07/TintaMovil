import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Un documento PDF que el usuario subió y analizó, con su metadata real
/// (páginas, tamaño) leída del archivo — nada de esto es inventado.
class RecentDocumentRecord {
  final String path;
  final String title;
  final int pages;
  final double sizeMb;
  final int recommendationsCount;
  final DateTime createdAt;

  const RecentDocumentRecord({
    required this.path,
    required this.title,
    required this.pages,
    required this.sizeMb,
    required this.recommendationsCount,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'title': title,
    'pages': pages,
    'sizeMb': sizeMb,
    'recommendationsCount': recommendationsCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RecentDocumentRecord.fromJson(Map<String, dynamic> json) {
    return RecentDocumentRecord(
      path: json['path'] as String,
      title: json['title'] as String,
      pages: json['pages'] as int? ?? 0,
      sizeMb: (json['sizeMb'] as num?)?.toDouble() ?? 0.0,
      recommendationsCount: json['recommendationsCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Guarda y consulta los documentos PDF que el usuario ha subido y
/// analizado, para la sección "Recientes" de Estudio. Persiste por
/// usuario en el dispositivo (no depende de un backend de listados).
class RecentDocumentsService {
  static String _key(String userId) => 'recent_documents_$userId';
  static const _maxStored = 20;

  /// Lee páginas y tamaño reales del PDF y guarda el registro. Se llama
  /// justo después de un análisis exitoso.
  static Future<RecentDocumentRecord> registerUpload(
      String userId, {
        required File file,
        required int recommendationsCount,
      }) async {
    int pages = 0;
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);
      pages = document.pages.count;
      document.dispose();
    } catch (_) {
      pages = 0;
    }

    final sizeBytes = await file.length();
    final sizeMb = sizeBytes / (1024 * 1024);

    final record = RecentDocumentRecord(
      path: file.path,
      title: _fileNameFrom(file.path),
      pages: pages,
      sizeMb: sizeMb,
      recommendationsCount: recommendationsCount,
      createdAt: DateTime.now(),
    );

    await _upsert(userId, record);
    return record;
  }

  static Future<void> _upsert(String userId, RecentDocumentRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? [];

    final records = raw
        .map((e) => RecentDocumentRecord.fromJson(json.decode(e) as Map<String, dynamic>))
        .where((r) => r.path != record.path)
        .toList()
      ..insert(0, record);

    final trimmed = records.take(_maxStored).toList();

    await prefs.setStringList(
      _key(userId),
      trimmed.map((r) => json.encode(r.toJson())).toList(),
    );
  }

  /// Documentos guardados, más reciente primero. Filtra los que ya no
  /// existen en disco (el caché del selector de archivos puede limpiarse).
  static Future<List<RecentDocumentRecord>> getAll(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? [];

    final records = raw
        .map((e) => RecentDocumentRecord.fromJson(json.decode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final existentes = <RecentDocumentRecord>[];
    for (final r in records) {
      if (await File(r.path).exists()) {
        existentes.add(r);
      }
    }
    return existentes;
  }

  static Future<void> remove(String userId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? [];

    final records = raw
        .map((e) => RecentDocumentRecord.fromJson(json.decode(e) as Map<String, dynamic>))
        .where((r) => r.path != path)
        .toList();

    await prefs.setStringList(
      _key(userId),
      records.map((r) => json.encode(r.toJson())).toList(),
    );
  }

  /// Borra el registro de todos los documentos recientes del usuario
  /// (Perfil > Privacidad > "Borrar documentos recientes"). No borra los
  /// archivos PDF en sí, solo la lista de "Recientes".
  static Future<void> clearAll(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }

  static String _fileNameFrom(String path) {
    final normalized = path.replaceAll('\\', '/');
    final name = normalized.split('/').last;
    return name.replaceAll('.pdf', '').replaceAll('.PDF', '');
  }
}