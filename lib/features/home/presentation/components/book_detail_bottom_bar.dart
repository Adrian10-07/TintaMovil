import 'package:flutter/material.dart';

/// Barra inferior del detalle: botón principal "Continuar leyendo" con
/// ícono de play, más un botón secundario circular (ej. para grupos
/// de estudio / compartir progreso).
class BookDetailBottomBar extends StatelessWidget {
  final VoidCallback onContinueReading;
  final VoidCallback? onSecondaryTap;
  final IconData secondaryIcon;

  const BookDetailBottomBar({
    Key? key,
    required this.onContinueReading,
    this.onSecondaryTap,
    this.secondaryIcon = Icons.groups_outlined,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onContinueReading,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: const Text(
                'Continuar leyendo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              onPressed: onSecondaryTap,
              icon: Icon(secondaryIcon, color: colorScheme.primary),
              iconSize: 22,
              padding: const EdgeInsets.all(14),
            ),
          ),
        ],
      ),
    );
  }
}