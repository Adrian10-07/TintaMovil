import 'package:flutter/material.dart';
import '../../../../core/ui/theme3material/theme.dart';
import 'auth_palette.dart';

/// Fondo decorativo compartido: blobs de color + grilla de puntos.
///
/// Antes cada view lo duplicaba. Ahora recibe la lista de blobs por
/// parámetro para poder variarla entre pantallas sin duplicar el
/// [CustomPainter] ni la lógica de posicionamiento.
class AuthBackground extends StatelessWidget {
  final List<_BlobData> blobs;

  const AuthBackground({super.key, required this.blobs});

  /// Preset "login": mint arriba/derecha, gold abajo/izquierda, peach medio.
  factory AuthBackground.login() => const AuthBackground(
        blobs: [
          _BlobData(top: -80, right: -60, size: 260, color: AuthPalette.mintPrimary, opacity: 0.14),
          _BlobData(bottom: -100, left: -80, size: 300, color: AuthPalette.warmGold, opacity: 0.10),
          _BlobData(top: 200, left: -40, size: 180, color: AuthPalette.peach, opacity: 0.08),
        ],
      );

  /// Preset "register": gold arriba/izquierda, mint abajo/derecha, peach medio.
  factory AuthBackground.register() => const AuthBackground(
        blobs: [
          _BlobData(top: -100, left: -80, size: 300, color: AuthPalette.warmGold, opacity: 0.12),
          _BlobData(bottom: -80, right: -60, size: 260, color: AuthPalette.mintPrimary, opacity: 0.14),
          _BlobData(top: 260, right: -30, size: 170, color: AuthPalette.peach, opacity: 0.08),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ...blobs.map((b) => Positioned(
              top: b.top,
              left: b.left,
              right: b.right,
              bottom: b.bottom,
              child: _Blob(color: b.color.withOpacity(b.opacity), size: b.size),
            )),
        // Reuso el DotGridPainter de core en vez de reimplementarlo aquí.
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: DotGridPainter(
                color: AuthPalette.lightText.withOpacity(0.045),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlobData {
  final double? top, left, right, bottom;
  final double size;
  final Color color;
  final double opacity;
  const _BlobData({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.opacity,
  });
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
