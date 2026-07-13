import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/document_chunk.dart';
import '../../domain/entities/indexed_document.dart';

/// Datasource SQLite para persistir la base de conocimientos local.
///
/// Tablas:
///   - `indexed_documents`: metadatos de documentos ya procesados.
///   - `document_chunks`: fragmentos de texto con sus vectores TF-IDF.
class KnowledgeLocalDatasource {
  static const String _dbName = 'tinta_knowledge.db';
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE indexed_documents (
            hash TEXT PRIMARY KEY,
            file_name TEXT NOT NULL,
            total_chunks INTEGER NOT NULL,
            indexed_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE document_chunks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_hash TEXT NOT NULL,
            chunk_index INTEGER NOT NULL,
            content TEXT NOT NULL,
            page_number INTEGER NOT NULL,
            tfidf_vector TEXT NOT NULL,
            FOREIGN KEY (document_hash) REFERENCES indexed_documents (hash)
              ON DELETE CASCADE
          )
        ''');

        // Índice para búsquedas rápidas por documento.
        await db.execute('''
          CREATE INDEX idx_chunks_doc_hash 
          ON document_chunks (document_hash)
        ''');
      },
    );
  }

  // ── Documentos ─────────────────────────────────────────────────────

  /// Verifica si un documento ya fue indexado.
  Future<bool> isDocumentIndexed(String hash) async {
    final db = await database;
    final result = await db.query(
      'indexed_documents',
      where: 'hash = ?',
      whereArgs: [hash],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Obtiene metadatos de un documento indexado.
  Future<IndexedDocument?> getDocument(String hash) async {
    final db = await database;
    final result = await db.query(
      'indexed_documents',
      where: 'hash = ?',
      whereArgs: [hash],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return IndexedDocument(
      hash: row['hash'] as String,
      fileName: row['file_name'] as String,
      totalChunks: row['total_chunks'] as int,
      indexedAt: DateTime.parse(row['indexed_at'] as String),
    );
  }

  /// Guarda los metadatos de un documento indexado.
  Future<void> saveDocument(IndexedDocument doc) async {
    final db = await database;
    await db.insert('indexed_documents', {
      'hash': doc.hash,
      'file_name': doc.fileName,
      'total_chunks': doc.totalChunks,
      'indexed_at': doc.indexedAt.toIso8601String(),
    });
  }

  // ── Chunks ─────────────────────────────────────────────────────────

  /// Guarda una lista de chunks en la base de datos (batch insert).
  Future<void> saveChunks(List<DocumentChunk> chunks) async {
    final db = await database;
    final batch = db.batch();

    for (final chunk in chunks) {
      batch.insert('document_chunks', {
        'document_hash': chunk.documentHash,
        'chunk_index': chunk.chunkIndex,
        'content': chunk.content,
        'page_number': chunk.pageNumber,
        'tfidf_vector': jsonEncode(chunk.tfidfVector),
      });
    }

    await batch.commit(noResult: true);
  }

  /// Obtiene todos los chunks de un documento.
  Future<List<DocumentChunk>> getChunks(String documentHash) async {
    final db = await database;
    final results = await db.query(
      'document_chunks',
      where: 'document_hash = ?',
      whereArgs: [documentHash],
      orderBy: 'chunk_index ASC',
    );

    return results.map((row) {
      final vectorJson = jsonDecode(row['tfidf_vector'] as String) as Map<String, dynamic>;
      final vector = vectorJson.map((k, v) => MapEntry(k, (v as num).toDouble()));

      return DocumentChunk(
        id: row['id'] as int,
        documentHash: row['document_hash'] as String,
        chunkIndex: row['chunk_index'] as int,
        content: row['content'] as String,
        pageNumber: row['page_number'] as int,
        tfidfVector: vector,
      );
    }).toList();
  }

  // ── Limpieza ───────────────────────────────────────────────────────

  /// Elimina un documento y todos sus chunks.
  Future<void> deleteDocument(String hash) async {
    final db = await database;
    await db.delete('document_chunks', where: 'document_hash = ?', whereArgs: [hash]);
    await db.delete('indexed_documents', where: 'hash = ?', whereArgs: [hash]);
  }

  /// Cierra la base de datos.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
