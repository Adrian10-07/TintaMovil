import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Una notificación in-app. No son push notifications del sistema
/// operativo — es una bandeja dentro de la app, persistida localmente
/// por usuario, generada por eventos reales (racha, recomendaciones).
class AppNotification {
  final String id;
  final String type; // 'streak' | 'recommendation' | 'general'
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
    id: id,
    type: type,
    title: title,
    body: body,
    createdAt: createdAt,
    read: read ?? this.read,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'title': title,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
    'read': read,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      read: json['read'] as bool? ?? false,
    );
  }
}

/// Guarda y consulta notificaciones in-app por usuario. Se dispara desde
/// eventos reales de la app (ver StreakService y UploadBookViewModel),
/// no son notificaciones push del sistema.
class NotificationService {
  static String _key(String userId) => 'app_notifications_$userId';
  static const _maxStored = 50;

  static Future<List<AppNotification>> getAll(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? [];
    final items = raw
        .map((e) => AppNotification.fromJson(json.decode(e) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<int> getUnreadCount(String userId) async {
    final items = await getAll(userId);
    return items.where((n) => !n.read).length;
  }

  /// Crea una nueva notificación. [id] es opcional — si no se da, se
  /// genera uno único; pásalo cuando quieras evitar duplicados exactos
  /// (ej. un mismo hito de racha en el mismo día).
  static Future<void> add(
      String userId, {
        required String type,
        required String title,
        required String body,
        String? id,
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? [];
    final items = raw
        .map((e) => AppNotification.fromJson(json.decode(e) as Map<String, dynamic>))
        .toList();

    final notifId = id ?? DateTime.now().microsecondsSinceEpoch.toString();

    // Evita duplicar la misma notificación (mismo id) si ya existe.
    if (items.any((n) => n.id == notifId)) return;

    items.insert(
      0,
      AppNotification(
        id: notifId,
        type: type,
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ),
    );

    final trimmed = items.take(_maxStored).toList();

    await prefs.setStringList(
      _key(userId),
      trimmed.map((n) => json.encode(n.toJson())).toList(),
    );
  }

  static Future<void> markAllRead(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key(userId)) ?? [];
    final items = raw
        .map((e) => AppNotification.fromJson(json.decode(e) as Map<String, dynamic>))
        .map((n) => n.copyWith(read: true))
        .toList();

    await prefs.setStringList(
      _key(userId),
      items.map((n) => json.encode(n.toJson())).toList(),
    );
  }
}