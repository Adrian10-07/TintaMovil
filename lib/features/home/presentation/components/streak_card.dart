import 'package:flutter/material.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';


class StreakCard extends StatelessWidget {
  final int streakDays;
  final List<int> completedDayIndices;

  const StreakCard({
    Key? key,
    this.streakDays = 14,
    this.completedDayIndices = const [0, 1, 2, 3, 4],
  }) : super(key: key);

  static const _dayLabels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: MaterialTheme.forestGradient(colorScheme),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Cabecera
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Racha de lectura',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: MaterialTheme.warmGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$streakDays días',
                  style: textTheme.labelSmall?.copyWith(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A2B1F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          //Burbujas de días
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final done = completedDayIndices.contains(i);
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: done
                      ? MaterialTheme.warmGold
                      : Colors.white.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: done
                      ? Text(
                    '✓',
                    style: textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A2B1F),
                    ),
                  )
                      : Text(
                    _dayLabels[i],
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}