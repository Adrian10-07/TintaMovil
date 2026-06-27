import 'package:flutter/material.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';

/// Indicador visual de fortaleza de contraseña con 3 segmentos.
///
/// Cambia de color según la longitud:
/// - < 6 chars → 1 segmento (error/coral)
/// - < 10 chars → 2 segmentos (warmGold)
/// - >= 10 chars → 3 segmentos (primary/mint)
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    Key? key,
    required this.password,
  }) : super(key: key);

  int get _strength {
    if (password.isEmpty) return 0;
    if (password.length < 6) return 1;
    if (password.length < 10) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = _strength;
    final labels = ['', 'Débil', 'Regular', 'Fuerte'];
    final colors = [
      Colors.transparent,
      colorScheme.error,
      MaterialTheme.warmGold,
      colorScheme.primary,
    ];

    return Row(
      children: [
        ...List.generate(3, (i) {
          final active = i < level;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: active
                    ? colors[level]
                    : colorScheme.onSurface.withOpacity(0.10),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 10),
        Text(
          level > 0 ? labels[level] : '',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: level > 0 ? colors[level] : Colors.transparent,
          ),
        ),
      ],
    );
  }
}