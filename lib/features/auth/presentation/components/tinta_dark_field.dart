import 'package:flutter/material.dart';
import 'auth_palette.dart';

/// TextFormField del flujo de auth, estilizado para fondo oscuro.
///
/// Antes vivía duplicado en login_view y register_view; ahora un solo
/// componente reutilizable respeta DRY y SRP (solo se encarga de la
/// presentación del campo, sin lógica de validación).
class TintaDarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final VoidCallback? onTap;

  const TintaDarkField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Uso textTheme donde puedo — solo sobreescribo el color porque el
    // fondo oscuro requiere blanco/gris en vez del onSurface del tema.
    final textTheme = Theme.of(context).textTheme;

    return TextFormField(
      controller: controller,
      onTap: onTap,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      style: textTheme.bodyLarge?.copyWith(
        color: AuthPalette.lightText,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: textTheme.bodyMedium?.copyWith(color: AuthPalette.mutedText),
        prefixIcon: Icon(icon, size: 20, color: AuthPalette.mutedText),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AuthPalette.fieldBlack,
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(color: AuthPalette.mintPrimary),
        errorBorder: _border(color: AuthPalette.coral),
        focusedErrorBorder: _border(color: AuthPalette.coral),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  // Un solo método para no repetir la geometría del borde 4 veces.
  OutlineInputBorder _border({Color? color}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            color == null ? BorderSide.none : BorderSide(color: color, width: 1.5),
      );
}
