import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinta/features/home/data/services/streak_service.dart';

void main() {
  const userId = 'test-user-1';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StreakService', () {
    test('primera lectura registrada da racha = 1', () async {
      final result = await StreakService.registerVisit(userId);
      expect(result.streakDays, 1);
    });

    test('leer dos veces el mismo día NO incrementa la racha', () async {
      await StreakService.registerVisit(userId);
      final second = await StreakService.registerVisit(userId);
      expect(second.streakDays, 1);
    });

    test('getCurrent no incrementa nada, solo lee lo guardado', () async {
      await StreakService.registerVisit(userId);
      final current = await StreakService.getCurrent(userId);
      expect(current.streakDays, 1);

      final currentAgain = await StreakService.getCurrent(userId);
      expect(currentAgain.streakDays, 1);
    });

    test('el día de la semana correspondiente queda marcado', () async {
      final result = await StreakService.registerVisit(userId);
      final todayIndex = DateTime.now().weekday - 1;
      expect(result.completedDayIndices, contains(todayIndex));
    });

    test('rachas de usuarios distintos no se mezclan', () async {
      await StreakService.registerVisit('usuario-A');
      await StreakService.registerVisit('usuario-A');
      final b = await StreakService.registerVisit('usuario-B');

      expect(b.streakDays, 1);
    });
  });
}