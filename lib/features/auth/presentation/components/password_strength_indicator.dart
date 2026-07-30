import 'package:flutter/material.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';

/// Indicador visual de fortaleza de contraseña con 3 segmentos.
///
/// Alineé las reglas con las que valida realmente el backend (mínimo 8,
/// al menos una letra y un dígito) — antes usaban solo la longitud y el
/// texto no coincidía con lo que la API aceptaba.
///
/// Acepta un [trackColor] opcional para adaptarse a fondos oscuros como
/// el del flujo de auth; si no se pasa, se resuelve desde el tema.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final Color? trackColor;

  const PasswordStrengthIndicator({
    Key? key,
    required this.password,
    this.trackColor,
  }) : super(key: key);

  // Extraje la evaluación para poder testearla y reusarla desde otro
  // widget si hiciera falta.
  int get _strength {
    if (password.isEmpty) return 0;
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    if (password.length < 8 || !hasLetter || !hasDigit) return 1;
    if (password.length < 12) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = _strength;
    const labels = ['', 'Débil', 'Regular', 'Fuerte'];
    final colors = [
      Colors.transparent,
      colorScheme.error,
      MaterialTheme.warmGold,
      colorScheme.primary,
    ];
    // Si el padre no manda trackColor, uso el gris estándar del tema.
    final track = trackColor ?? colorScheme.onSurface.withOpacity(0.10);

    return Row(
      children: [
        ...List.generate(3, (i) {
          final active = i < level;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: active ? colors[level] : track,
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
