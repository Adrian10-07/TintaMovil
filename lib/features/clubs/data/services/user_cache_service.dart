import 'package:flutter/foundation.dart';

import '../../../../core/network/http_client.dart';

/// Perfil público de un usuario (solo id, name, avatarUrl).
class PublicUser {
  final String id;
  final String name;
  final String? avatarUrl;

  const PublicUser({required this.id, required this.name, this.avatarUrl});

  factory PublicUser.fromJson(Map<String, dynamic> json) {
    return PublicUser(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

/// Servicio que resuelve user IDs a nombres usando el endpoint público
/// de Identity (`GET /users/:id`) y los cachea en memoria.
///
/// Evita requests repetidos para el mismo usuario. El caché vive
/// mientras la app esté abierta — se limpia al reiniciar.
class UserCacheService {
  final ApiClient _api;

  static const String _identityUrl =
      'https://tinta-identity.up.railway.app/api/v1';

  /// Caché en memoria: userId → PublicUser.
  final Map<String, PublicUser> _cache = {};

  /// Requests en vuelo para evitar duplicados concurrentes.
  final Map<String, Future<PublicUser?>> _pending = {};

  UserCacheService(this._api);

  /// Obtiene el nombre de un usuario (desde caché o API).
  /// Retorna null si el usuario no existe o hay error.
  Future<String?> getUserName(String userId) async {
    final user = await getUser(userId);
    return user?.name;
  }

  /// Obtiene el perfil público de un usuario.
  Future<PublicUser?> getUser(String userId) async {
    // 1. Check caché.
    if (_cache.containsKey(userId)) return _cache[userId];

    // 2. Check si ya hay un request en vuelo para este userId.
    if (_pending.containsKey(userId)) return _pending[userId];

    // 3. Fetch y cachear.
    final future = _fetchAndCache(userId);
    _pending[userId] = future;
    try {
      return await future;
    } finally {
      _pending.remove(userId);
    }
  }

  Future<PublicUser?> _fetchAndCache(String userId) async {
    try {
      final data = await _api.get('$_identityUrl/users/$userId');
      final user = PublicUser.fromJson(data as Map<String, dynamic>);
      _cache[userId] = user;
      return user;
    } catch (e) {
      debugPrint('UserCacheService: failed to resolve $userId: $e');
      return null;
    }
  }

  /// Resuelve múltiples userIds en paralelo.
  /// Retorna un mapa userId → nombre.
  Future<Map<String, String>> resolveNames(Set<String> userIds) async {
    final results = <String, String>{};
    final toFetch = <String>[];

    for (final id in userIds) {
      if (_cache.containsKey(id)) {
        results[id] = _cache[id]!.name;
      } else {
        toFetch.add(id);
      }
    }

    if (toFetch.isNotEmpty) {
      await Future.wait(toFetch.map((id) async {
        final user = await getUser(id);
        if (user != null) results[id] = user.name;
      }));
    }

    return results;
  }

  /// Limpia el caché (para logout, por ejemplo).
  void clear() {
    _cache.clear();
    _pending.clear();
  }
}
