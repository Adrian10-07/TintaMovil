import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../../domain/entities/discussion.dart';
import '../models/discussion_model.dart';

/// DataSource local para caché de discusiones del chat.
///
/// Usa SQLite (sqflite, ya incluido en el proyecto) para almacenar
/// los mensajes más recientes de cada club con estrategia cache-first.
class ClubLocalDataSource {
  static const String _dbName = 'tinta_clubs_cache.db';
  static const int _dbVersion = 2;
  static const int _maxMessagesPerClub = 500;

  Database? _db;

  /// Obtiene (o crea) la instancia de la base de datos.
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Migración de v1 → v2: agregar columnas de image, pin, message_type.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE cached_discussions ADD COLUMN message_type TEXT');
      await db.execute('ALTER TABLE cached_discussions ADD COLUMN image_url TEXT');
      await db.execute('ALTER TABLE cached_discussions ADD COLUMN is_pinned INTEGER DEFAULT 0');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cached_discussions (
        id          TEXT PRIMARY KEY,
        club_id     TEXT NOT NULL,
        user_id     TEXT NOT NULL,
        chapter_number INTEGER,
        content     TEXT NOT NULL,
        moderation_flag TEXT,
        message_type TEXT,
        image_url   TEXT,
        is_pinned   INTEGER DEFAULT 0,
        created_at  INTEGER NOT NULL,
        updated_at  INTEGER NOT NULL,
        user_name   TEXT,
        synced_at   INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_cached_disc_club
        ON cached_discussions(club_id, created_at DESC)
    ''');

    // Tabla auxiliar para guardar el último timestamp sincronizado por club.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_metadata (
        club_id         TEXT PRIMARY KEY,
        last_synced_at  TEXT NOT NULL
      )
    ''');
  }

  // ── Lecturas ────────────────────────────────────────────────────────────

  /// Obtiene mensajes cacheados de un club, ordenados del más nuevo al viejo.
  Future<List<Discussion>> getDiscussions(
      String clubId, {
        int limit = 50,
        int offset = 0,
      }) async {
    final db = await database;
    final rows = await db.query(
      'cached_discussions',
      where: 'club_id = ?',
      whereArgs: [clubId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map((r) => DiscussionModel.fromSqlite(r)).toList();
  }

  /// Obtiene el timestamp ISO-8601 de la última sincronización de un club.
  Future<String?> getLastSyncedAt(String clubId) async {
    final db = await database;
    final rows = await db.query(
      'sync_metadata',
      where: 'club_id = ?',
      whereArgs: [clubId],
    );
    if (rows.isEmpty) return null;
    return rows.first['last_synced_at'] as String;
  }

  /// Cuenta cuántos mensajes hay cacheados de un club.
  Future<int> countDiscussions(String clubId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM cached_discussions WHERE club_id = ?',
      [clubId],
    );
    return (result.first['c'] as int?) ?? 0;
  }

  // ── Escrituras ──────────────────────────────────────────────────────────

  /// Inserta o reemplaza una lista de discusiones en caché.
  Future<void> upsertDiscussions(List<Discussion> discussions) async {
    if (discussions.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final d in discussions) {
      final model = d is DiscussionModel
          ? d
          : DiscussionModel(
        id: d.id,
        clubId: d.clubId,
        userId: d.userId,
        chapterNumber: d.chapterNumber,
        content: d.content,
        moderationFlag: d.moderationFlag,
        createdAt: d.createdAt,
        updatedAt: d.updatedAt,
        userName: d.userName,
      );
      batch.insert(
        'cached_discussions',
        {
          ...model.toSqlite(),
          'synced_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);

    // Recortar si excede el máximo por club.
    if (discussions.isNotEmpty) {
      await _trimCache(discussions.first.clubId);
    }
  }

  /// Actualiza el timestamp de última sincronización.
  Future<void> setLastSyncedAt(String clubId, String isoTimestamp) async {
    final db = await database;
    await db.insert(
      'sync_metadata',
      {'club_id': clubId, 'last_synced_at': isoTimestamp},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Elimina todos los mensajes cacheados de un club.
  Future<void> clearClub(String clubId) async {
    final db = await database;
    await db.delete('cached_discussions',
        where: 'club_id = ?', whereArgs: [clubId]);
    await db.delete('sync_metadata',
        where: 'club_id = ?', whereArgs: [clubId]);
  }

  /// Elimina un mensaje específico del caché.
  Future<void> deleteDiscussion(String discussionId) async {
    final db = await database;
    await db.delete('cached_discussions',
        where: 'id = ?', whereArgs: [discussionId]);
  }

  /// Elimina toda la base de datos de caché.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('cached_discussions');
    await db.delete('sync_metadata');
  }

  // ── Internas ────────────────────────────────────────────────────────────

  /// Mantiene solo los últimos [_maxMessagesPerClub] mensajes de un club.
  Future<void> _trimCache(String clubId) async {
    final count = await countDiscussions(clubId);
    if (count <= _maxMessagesPerClub) return;

    final db = await database;
    await db.rawDelete('''
      DELETE FROM cached_discussions
      WHERE club_id = ? AND id NOT IN (
        SELECT id FROM cached_discussions
        WHERE club_id = ?
        ORDER BY created_at DESC
        LIMIT ?
      )
    ''', [clubId, clubId, _maxMessagesPerClub]);
  }

  /// Cierra la base de datos (para cleanup).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}