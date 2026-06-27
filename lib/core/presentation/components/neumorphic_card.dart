import 'package:flutter/material.dart';

/// Botón de login social (Google, Apple, etc.)
///
/// Solo UI — sin lógica de autenticación.
class SocialLoginButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  const SocialLoginButton({
    Key? key,
    required this.label,
    required this.icon,
    this.onPressed,
  }) : super(key: key);

  /// Variante preconfigurada para Google.
  factory SocialLoginButton.google({VoidCallback? onPressed}) {
    return SocialLoginButton(
      label: 'Continuar con Google',
      icon: const Icon(
        Icons.g_mobiledata_rounded,
        size: 24,
        color: Color(0xFF4285F4),
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: icon,
      label: Text(label),
    );
  }
}

/// Separador visual "— o —" para secciones de auth.
class AuthDivider extends StatelessWidget {
  final String text;

  const AuthDivider({Key? key, this.text = 'o'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.35),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Link al pie de auth: "¿Ya tienes cuenta? Inicia sesión"
class AuthFooterLink extends StatelessWidget {
  final String message;
  final String actionText;
  final VoidCallback onTap;

  const AuthFooterLink({
    Key? key,
    required this.message,
    required this.actionText,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: textTheme.bodyMedium),
          GestureDetector(
            onTap: onTap,
            child: Text(
              actionText,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}