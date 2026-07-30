import 'package:flutter/material.dart';
import 'auth_palette.dart';

/// Botón primario de auth con estado de carga incorporado.
///
/// Estaba duplicado (login e register) con la misma decoración y el
/// mismo spinner. Ahora recibe [isLoading] y [label] y se encarga de
/// mostrar el CircularProgressIndicator cuando toca.
class AuthPrimaryButton extends StatelessWidget {
  final bool isLoading;
  final String label;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.isLoading,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthPalette.mintPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AuthPalette.mintPrimary.withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                // Uso el textTheme y sobreescribo el fontWeight — así el
                // tamaño real lo controla el tema global.
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
              ),
      ),
    );
  }
}
