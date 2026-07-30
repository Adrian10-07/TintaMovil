import 'package:flutter/material.dart';
import 'auth_palette.dart';

/// Logo + palabra "tinta" que va arriba de los formularios de auth.
///
/// Lo saqué del view para dejar de repetirlo y para poder ajustar el
/// tamaño/tipografía en un solo sitio.
class AuthWordmark extends StatelessWidget {
  const AuthWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Image.asset(
            'assets/icon/icon.png',
            fit: BoxFit.cover,
            // Fallback por si el asset se renombra o falta — el flujo de
            // login no puede romperse por un ícono.
            errorBuilder: (_, __, ___) => Container(
              color: AuthPalette.mintPrimary,
              child: const Icon(Icons.auto_stories_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'tinta',
          style: textTheme.headlineSmall?.copyWith(
            color: AuthPalette.lightText,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}
