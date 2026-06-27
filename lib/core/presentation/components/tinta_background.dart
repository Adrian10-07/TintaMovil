import 'package:flutter/material.dart';
import 'package:tinta/core/ui/theme3material/theme.dart';

/// Fondo decorativo Memphis-moderno con blobs radiales difusos y grilla de puntos.
///
/// Envuelve el contenido hijo con un Stack que incluye:
/// - Blobs de color posicionados (hasta 3)
/// - Grilla de puntos sutil
/// - El contenido pasado como [child]
///
/// ```dart
/// TintaBackground(
///   blobs: [
///     BlobConfig(top: -80, right: -60, color: colorScheme.primary, size: 260),
///     BlobConfig(bottom: -100, left: -80, color: MaterialTheme.warmGold, size: 300),
///   ],
///   child: SafeArea(child: MyContent()),
/// )
/// ```
class TintaBackground extends StatelessWidget {
  final Widget child;
  final List<BlobConfig> blobs;
  final bool showDotGrid;

  const TintaBackground({
    Key? key,
    required this.child,
    this.blobs = const [],
    this.showDotGrid = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        // Blobs decorativos
        for (final blob in blobs)
          Positioned(
            top: blob.top,
            left: blob.left,
            right: blob.right,
            bottom: blob.bottom,
            child: Container(
              width: blob.size,
              height: blob.size,
              decoration: BoxDecoration(
                color: blob.color.withOpacity(blob.opacity),
                shape: BoxShape.circle,
              ),
            ),
          ),

        // Grilla de puntos
        if (showDotGrid)
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(
                color: colorScheme.onSurface.withOpacity(0.045),
              ),
            ),
          ),

        // Contenido
        child,
      ],
    );
  }
}

/// Configuración de un blob decorativo individual.
class BlobConfig {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Color color;
  final double size;
  final double opacity;

  const BlobConfig({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.color,
    required this.size,
    this.opacity = 0.15,
  });
}