import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinta/features/achievements/data/services/achievement_service.dart';

void main() {
  const userId = 'test-user-achievements';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AchievementService', () {
    test('sin logros desbloqueados, los puntos son 0', () async {
      final points = await AchievementService.getTotalPoints(userId);
      expect(points, 0);
    });

    test('checkStreak(1) desbloquea solo el logro de racha=1', () async {
      await AchievementService.checkStreak(userId, 1);
      final unlocked = await AchievementService.getUnlocked(userId);

      expect(unlocked, contains('streak_1'));
      expect(unlocked, isNot(contains('streak_3')));
    });

    test('checkStreak(7) desbloquea todos los logros de racha hasta 7',
            () async {
          await AchievementService.checkStreak(userId, 7);
          final unlocked = await AchievementService.getUnlocked(userId);

          expect(unlocked, containsAll(['streak_1', 'streak_3', 'streak_7']));
          expect(unlocked, isNot(contains('streak_30')));
        });

    test('un logro no se desbloquea dos veces (puntos no se duplican)',
            () async {
          await AchievementService.checkStreak(userId, 3);
          final pointsFirst = await AchievementService.getTotalPoints(userId);

          await AchievementService.checkStreak(userId, 3);
          final pointsSecond = await AchievementService.getTotalPoints(userId);

          expect(pointsFirst, pointsSecond);
        });

    test('checkBooksFinished(5) desbloquea logro de bibliófilo', () async {
      await AchievementService.checkBooksFinished(userId, 5);
      final unlocked = await AchievementService.getUnlocked(userId);

      expect(unlocked, containsAll(['book_finished_1', 'book_finished_5']));
    });

    test('checkUploads(1) NO desbloquea el de 5 documentos todavía',
            () async {
          await AchievementService.checkUploads(userId, 1);
          final unlocked = await AchievementService.getUnlocked(userId);

          expect(unlocked, contains('upload_1'));
          expect(unlocked, isNot(contains('upload_5')));
        });

    test('el nivel de lector sube conforme suben los puntos', () async {
      expect(AchievementService.levelFor(0).level, 1);
      expect(AchievementService.levelFor(25).level, 2);
      expect(AchievementService.levelFor(75).level, 3);
      expect(AchievementService.levelFor(150).level, 4);
      expect(AchievementService.levelFor(300).level, 5);
    });

    test('los puntos totales suman correctamente los logros desbloqueados',
            () async {
          await AchievementService.checkStreak(userId, 3);
          final points = await AchievementService.getTotalPoints(userId);
          expect(points, 35);
        });
  });
}