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
    final todayIndex = DateTime.now().weekday - 1; // 0=Lunes ... 6=Domingo

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        gradient: MaterialTheme.forestGradient(colorScheme),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: MaterialTheme.warmGold.withOpacity(0.18),
            offset: const Offset(0, 10),
            blurRadius: 24,
            spreadRadius: -6,
          ),
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.25),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Text(
            'Racha de lectura',
            style: textTheme.labelLarge?.copyWith(
              color: Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),

          // Número de racha — elemento hero, imposible de perderse.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MaterialTheme.warmGold.withOpacity(0.16),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                '$streakDays',
                style: textTheme.displaySmall?.copyWith(
                  fontFamily: 'PlusJakartaSans',
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  streakDays == 1 ? 'día seguido' : 'días seguidos',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Burbujas de días
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final done = completedDayIndices.contains(i);
              final isToday = i == todayIndex;
              return Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: done
                          ? MaterialTheme.warmGold
                          : Colors.white.withOpacity(0.14),
                      shape: BoxShape.circle,
                      border: isToday && !done
                          ? Border.all(
                        color: MaterialTheme.warmGold,
                        width: 2,
                      )
                          : null,
                    ),
                    child: Center(
                      child: done
                          ? const Text(
                        '✓',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A2B1F),
                        ),
                      )
                          : Text(
                        _dayLabels[i],
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                          color: Colors.white.withOpacity(isToday ? 0.95 : 0.55),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? MaterialTheme.warmGold
                          : Colors.transparent,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}