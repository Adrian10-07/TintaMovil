import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tinta/features/achievements/presentation/views/achievements_view.dart';
import 'package:tinta/features/achievements/data/services/achievement_service.dart';
import 'package:tinta/features/user/presentation/views/notification_settings_view.dart';
import 'package:tinta/features/notifications/data/services/notification_settings_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const userId = 'integration-test-user';

  setUp(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  });

  group('Logros — integración', () {
    testWidgets('la pantalla arranca en 0 puntos y sin logros', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: AchievementsView(userId: userId),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('0 puntos'), findsOneWidget);
      expect(find.textContaining('0 de ${AchievementService.catalog.length} logros'),
          findsOneWidget);
    });

    testWidgets('al desbloquear un logro real, la pantalla lo refleja al recargar',
        (tester) async {
      await AchievementService.checkStreak(userId, 3);

      await tester.pumpWidget(const MaterialApp(
        home: AchievementsView(userId: userId),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('35 puntos'), findsOneWidget);
      expect(find.text('Constancia'), findsOneWidget);
    });
  });

  group('Notificaciones — integración', () {
    testWidgets('apagar un switch persiste de verdad entre pantallas',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: NotificationSettingsView(userId: userId),
      ));
      await tester.pumpAndSettle();

      final firstSwitch = find.byType(Switch).first;
      await tester.tap(firstSwitch);
      await tester.pumpAndSettle();

      final enabled =
      await NotificationSettingsService.isEnabled(userId, 'streak');
      expect(enabled, isFalse);
    });
  });
}
