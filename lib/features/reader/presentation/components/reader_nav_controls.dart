import 'package:flutter/material.dart';

/// Controles de navegación entre páginas del lector.
class ReaderNavControls extends StatelessWidget {
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSave;
  final bool isSaving;

  const ReaderNavControls({
    Key? key,
    required this.canGoBack,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
    required this.onSave,
    this.isSaving = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Anterior
          _NavButton(
            icon: Icons.chevron_left_rounded,
            label: 'Anterior',
            onTap: canGoBack ? onPrevious : null,
          ),

          // Guardar progreso
          GestureDetector(
            onTap: isSaving ? null : onSave,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: isSaving
                  ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save_outlined,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Guardar',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),

          // Siguiente
          _NavButton(
            icon: Icons.chevron_right_rounded,
            label: 'Siguiente',
            onTap: canGoForward ? onNext : null,
            reversed: true,
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool reversed;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.reversed = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final color = enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.25);

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: reversed
            ? [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
          const SizedBox(width: 4),
          Icon(icon, size: 24, color: color),
        ]
            : [
          Icon(icon, size: 24, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}