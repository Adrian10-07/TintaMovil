import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tinta/features/home/presentation/components/streak_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('muestra el número de días de racha recibido', (tester) async {
    await tester.pumpWidget(wrap(const StreakCard(
      streakDays: 5,
      completedDayIndices: [0, 1],
    )));

    expect(find.text('5'), findsOneWidget);
    expect(find.textContaining('días seguidos'), findsOneWidget);
  });

  testWidgets('con 1 día muestra singular ("día seguido")', (tester) async {
    await tester.pumpWidget(wrap(const StreakCard(
      streakDays: 1,
      completedDayIndices: [0],
    )));

    expect(find.text('día seguido'), findsOneWidget);
  });

  testWidgets('marca con check los días completados de la semana',
          (tester) async {
        await tester.pumpWidget(wrap(const StreakCard(
          streakDays: 3,
          completedDayIndices: [0, 1, 2],
        )));

        expect(find.text('✓'), findsNWidgets(3));
      });
}