import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/document_registry.dart';

/// Implementación de [DocumentRegistry] con SharedPreferences.
///
/// Guarda un mapa JSON: hash_sha256 → { document_id, filename, uploaded_at }.
/// Todo bajo la misma key para simplificar carga y guardado.
class DocumentRegistryImpl implements DocumentRegistry {
  static const _storageKey = 'tutor_ai.document_registry.v1';

  Future<Map<String, Map<String, dynamic>>> _loadRegistry() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map(
            (k, v) => MapEntry(k, (v as Map).cast<String, dynamic>()),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveRegistry(Map<String, Map<String, dynamic>> registry) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(registry));
  }

  @override
  Future<String?> getDocumentIdByHash(String hash) async {
    final registry = await _loadRegistry();
    final entry = registry[hash];
    return entry?['document_id'] as String?;
  }

  @override
  Future<void> saveMapping({
    required String hash,
    required String documentId,
    required String filename,
  }) async {
    final registry = await _loadRegistry();
    registry[hash] = {
      'document_id': documentId,
      'filename': filename,
      'uploaded_at': DateTime.now().toIso8601String(),
    };
    await _saveRegistry(registry);
  }

  @override
  Future<void> removeByHash(String hash) async {
    final registry = await _loadRegistry();
    registry.remove(hash);
    await _saveRegistry(registry);
  }
}
