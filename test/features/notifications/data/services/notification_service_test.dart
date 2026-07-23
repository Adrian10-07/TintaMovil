import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinta/features/notifications/data/services/notification_settings_service.dart';
import 'package:tinta/features/notifications/data/services/notification_service.dart';

void main() {
  const userId = 'test-user-notifications';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('NotificationSettingsService', () {
    test('por defecto todos los tipos están habilitados', () async {
      final enabled = await NotificationSettingsService.isEnabled(userId, 'streak');
      expect(enabled, isTrue);
    });

    test('se puede apagar un tipo específico', () async {
      await NotificationSettingsService.setEnabled(userId, 'streak', false);
      final enabled = await NotificationSettingsService.isEnabled(userId, 'streak');
      expect(enabled, isFalse);
    });

    test('apagar un tipo no afecta a los demás', () async {
      await NotificationSettingsService.setEnabled(userId, 'streak', false);
      final uploadStillOn =
      await NotificationSettingsService.isEnabled(userId, 'upload');
      expect(uploadStillOn, isTrue);
    });
  });

  group('NotificationService respeta las preferencias', () {
    test('si el tipo está apagado, add() no crea la notificación', () async {
      await NotificationSettingsService.setEnabled(userId, 'streak', false);

      await NotificationService.add(
        userId,
        type: 'streak',
        title: 'Prueba',
        body: 'Esto no debería guardarse',
      );

      final all = await NotificationService.getAll(userId);
      expect(all, isEmpty);
    });

    test('si el tipo está encendido, add() sí crea la notificación', () async {
      await NotificationService.add(
        userId,
        type: 'upload',
        title: 'Documento subido',
        body: 'Se analizó correctamente',
      );

      final all = await NotificationService.getAll(userId);
      expect(all, hasLength(1));
      expect(all.first.title, 'Documento subido');
    });

    test('no se duplica una notificación con el mismo id', () async {
      await NotificationService.add(
        userId,
        type: 'upload',
        title: 'Doc',
        body: 'Body',
        id: 'mismo-id',
      );
      await NotificationService.add(
        userId,
        type: 'upload',
        title: 'Doc otra vez',
        body: 'Otro body',
        id: 'mismo-id',
      );

      final all = await NotificationService.getAll(userId);
      expect(all, hasLength(1));
    });

    test('markAllRead pone en true el campo read de todas', () async {
      await NotificationService.add(userId, type: 'upload', title: 'A', body: 'a');
      await NotificationService.add(userId, type: 'upload', title: 'B', body: 'b');

      await NotificationService.markAllRead(userId);

      final unread = await NotificationService.getUnreadCount(userId);
      expect(unread, 0);
    });

    test('clearAll borra la bandeja completa', () async {
      await NotificationService.add(userId, type: 'upload', title: 'A', body: 'a');
      await NotificationService.clearAll(userId);

      final all = await NotificationService.getAll(userId);
      expect(all, isEmpty);
    });
  });
}