import 'package:shared_preferences/shared_preferences.dart';

/// Resultado de calcular/actualizar la racha de un usuario.
class StreakResult {
  final int streakDays;
  final List<int> completedDayIndices; // 0=Lunes ... 6=Domingo

  const StreakResult({
    required this.streakDays,
    required this.completedDayIndices,
  });
}

/// Lleva el conteo de "racha de lectura" en base a los días en que el
/// usuario abre sesión (login exitoso).
///
/// Reglas:
/// - Primer login registrado → racha = 1.
/// - Login en un día consecutivo al último registrado → racha += 1.
/// - Login el mismo día ya registrado → no cambia nada (idempotente).
/// - Si se salta uno o más días → racha se reinicia a 1.
///
/// Todo se guarda en SharedPreferences, con claves por usuario para no
/// mezclar rachas si hay varias cuentas en el mismo dispositivo.
class StreakService {
  static String _lastLoginKey(String userId) => 'streak_last_login_$userId';
  static String _streakKey(String userId) => 'streak_days_$userId';
  static String _weekStartKey(String userId) => 'streak_week_start_$userId';
  static String _weekDaysKey(String userId) => 'streak_week_days_$userId';

  /// Registra la visita/login de hoy y regresa la racha actualizada.
  /// Llamar justo después de un login (o registro) exitoso.
  static Future<StreakResult> registerVisit(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateOnly(DateTime.now());

    final lastLoginStr = prefs.getString(_lastLoginKey(userId));
    final lastLogin = lastLoginStr != null ? DateTime.parse(lastLoginStr) : null;

    int streak = prefs.getInt(_streakKey(userId)) ?? 0;

    if (lastLogin == null) {
      streak = 1;
    } else {
      final diff = today.difference(lastLogin).inDays;
      if (diff == 0) {
        // Ya contaba hoy, no hacer nada más que refrescar el día completado.
      } else if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
      // diff < 0 (reloj del dispositivo cambiado hacia atrás): se ignora.
    }

    await prefs.setString(_lastLoginKey(userId), today.toIso8601String());
    await prefs.setInt(_streakKey(userId), streak);

    final completedDays = await _registerDayInWeek(prefs, userId, today);

    return StreakResult(streakDays: streak, completedDayIndices: completedDays);
  }

  /// Solo lee el estado guardado, sin registrar una nueva visita.
  /// Útil para pintar la UI sin volver a contar el día.
  static Future<StreakResult> getCurrent(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final streak = prefs.getInt(_streakKey(userId)) ?? 0;
    final days = prefs.getStringList(_weekDaysKey(userId))
        ?.map(int.parse)
        .toList() ??
        <int>[];
    return StreakResult(streakDays: streak, completedDayIndices: days);
  }

  static Future<List<int>> _registerDayInWeek(
      SharedPreferences prefs,
      String userId,
      DateTime today,
      ) async {
    // Lunes de la semana actual.
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    final storedWeekStartStr = prefs.getString(_weekStartKey(userId));
    final storedWeekStart =
    storedWeekStartStr != null ? DateTime.parse(storedWeekStartStr) : null;

    List<int> days;
    if (storedWeekStart == null || !_isSameDay(storedWeekStart, weekStart)) {
      // Nueva semana: reiniciar burbujas.
      days = [];
      await prefs.setString(_weekStartKey(userId), weekStart.toIso8601String());
    } else {
      days = prefs.getStringList(_weekDaysKey(userId))
          ?.map(int.parse)
          .toList() ??
          <int>[];
    }

    final todayIndex = today.weekday - 1; // 0=Lunes ... 6=Domingo
    if (!days.contains(todayIndex)) {
      days.add(todayIndex);
    }

    await prefs.setStringList(
      _weekDaysKey(userId),
      days.map((d) => d.toString()).toList(),
    );

    return days;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}