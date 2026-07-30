import 'package:flutter/material.dart';
import 'auth_palette.dart';

/// Tarjeta contenedora oscura (para agrupar campos en auth).
///
/// Extracción directa del widget privado que estaba duplicado en
/// login/register — así el radio/borde/padding vive en un solo lugar.
class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AuthPalette.cardBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}
