import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinta/features/reader/data/services/reading_library_service.dart';

void main() {
  const userId = 'test-user-reading';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ReadingLibraryEntry buildEntry({
    String bookId = 'book-1',
    int currentPage = 2,
    int totalPages = 10,
  }) {
    return ReadingLibraryEntry(
      bookId: bookId,
      title: 'Libro de prueba',
      author: 'Autor de prueba',
      currentPage: currentPage,
      totalPages: totalPages,
      lastReadAt: DateTime.now(),
    );
  }

  group('ReadingLibraryEntry', () {
    test('calcula el progreso correctamente', () {
      final entry = buildEntry(currentPage: 2, totalPages: 4);
      expect(entry.progress, 0.5);
      expect(entry.percent, 50);
    });

    test('progreso nunca pasa de 1.0 aunque currentPage sea mayor', () {
      final entry = buildEntry(currentPage: 20, totalPages: 10);
      expect(entry.progress, 1.0);
    });

    test('totalPages en 0 no truena y da progreso 0', () {
      final entry = buildEntry(currentPage: 5, totalPages: 0);
      expect(entry.progress, 0.0);
    });
  });

  group('ReadingLibraryService', () {
    test('upsert guarda una entrada y getInProgress la regresa', () async {
      await ReadingLibraryService.upsert(userId, buildEntry());
      final list = await ReadingLibraryService.getInProgress(userId);

      expect(list, hasLength(1));
      expect(list.first.bookId, 'book-1');
    });

    test('upsert del mismo bookId actualiza en vez de duplicar', () async {
      await ReadingLibraryService.upsert(userId, buildEntry(currentPage: 2));
      await ReadingLibraryService.upsert(userId, buildEntry(currentPage: 5));

      final list = await ReadingLibraryService.getInProgress(userId);
      expect(list, hasLength(1));
      expect(list.first.currentPage, 5);
    });

    test('libros con progreso >=98% NO aparecen en getInProgress', () async {
      await ReadingLibraryService.upsert(
        userId,
        buildEntry(bookId: 'terminado', currentPage: 10, totalPages: 10),
      );

      final list = await ReadingLibraryService.getInProgress(userId);
      expect(list, isEmpty);
    });

    test('getAllIndexed SÍ incluye los libros terminados', () async {
      await ReadingLibraryService.upsert(
        userId,
        buildEntry(bookId: 'terminado', currentPage: 10, totalPages: 10),
      );

      final indexed = await ReadingLibraryService.getAllIndexed(userId);
      expect(indexed.containsKey('terminado'), isTrue);
      expect(indexed['terminado']!.progress, 1.0);
    });

    test('remove borra solo el libro indicado', () async {
      await ReadingLibraryService.upsert(userId, buildEntry(bookId: 'a'));
      await ReadingLibraryService.upsert(userId, buildEntry(bookId: 'b'));

      await ReadingLibraryService.remove(userId, 'a');

      final list = await ReadingLibraryService.getInProgress(userId);
      expect(list, hasLength(1));
      expect(list.first.bookId, 'b');
    });

    test('clearAll borra todo el historial del usuario', () async {
      await ReadingLibraryService.upsert(userId, buildEntry(bookId: 'a'));
      await ReadingLibraryService.upsert(userId, buildEntry(bookId: 'b'));

      await ReadingLibraryService.clearAll(userId);

      final list = await ReadingLibraryService.getInProgress(userId);
      expect(list, isEmpty);
    });

    test('los datos de un usuario no afectan a otro', () async {
      await ReadingLibraryService.upsert(
        'usuario-A',
        buildEntry(bookId: 'libro-de-A'),
      );

      final listaB = await ReadingLibraryService.getInProgress('usuario-B');
      expect(listaB, isEmpty);
    });
  });
}