import '../../../notifications/data/services/notification_service.dart';
import '../../domain/achievement_catalog.dart';
import '../../domain/entities/achievement_def.dart';
import '../repositories/achievement_repository.dart';

/// Punto de entrada del sistema de logros: decide CUÁNDO desbloquear un
/// logro (según racha, libros terminados o documentos subidos) y dispara
/// la notificación correspondiente.

class AchievementService {
  static final AchievementRepository _repository = AchievementRepository();

  static List<AchievementDef> get catalog => AchievementCatalog.all;

  static Future<Set<String>> getUnlocked(String userId) =>
      _repository.getUnlocked(userId);

  static Future<int> getTotalPoints(String userId) =>
      _repository.getTotalPoints(userId);

  static ReaderLevel levelFor(int points) => AchievementCatalog.levelFor(points);

  static Future<void> _unlockAndNotify(String userId, String achievementId) async {
    final wasNew = await _repository.unlock(userId, achievementId);
    if (!wasNew) return;

    final def = AchievementCatalog.byId(achievementId);
    await NotificationService.add(
      userId,
      type: 'achievement',
      title: '¡Logro desbloqueado! 🏆',
      body: '${def.title} — +${def.points} puntos',
      id: 'achievement_${userId}_$achievementId',
    );
  }

  /// Llamar cada vez que se actualiza la racha de lectura.
  static Future<void> checkStreak(String userId, int streakDays) async {
    if (streakDays >= 1) await _unlockAndNotify(userId, 'streak_1');
    if (streakDays >= 3) await _unlockAndNotify(userId, 'streak_3');
    if (streakDays >= 7) await _unlockAndNotify(userId, 'streak_7');
    if (streakDays >= 30) await _unlockAndNotify(userId, 'streak_30');
  }

  /// Llamar cada vez que un libro llega a >=98% de progreso.
  static Future<void> checkBooksFinished(String userId, int count) async {
    if (count >= 1) await _unlockAndNotify(userId, 'book_finished_1');
    if (count >= 5) await _unlockAndNotify(userId, 'book_finished_5');
  }

  /// Llamar cada vez que se sube y analiza un documento con éxito.
  static Future<void> checkUploads(String userId, int count) async {
    if (count >= 1) await _unlockAndNotify(userId, 'upload_1');
    if (count >= 5) await _unlockAndNotify(userId, 'upload_5');
  }
}