import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Zona de subida con borde punteado, ícono central, título y subtítulo.
/// Replica el "dropzone" de la imagen de referencia.
class UploadDropzone extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasSelection;
  final String selectedFileName;

  const UploadDropzone({
    Key? key,
    required this.onTap,
    this.hasSelection = false,
    this.selectedFileName = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: colorScheme.primary.withOpacity(0.45),
          radius: 20,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  hasSelection
                      ? Icons.picture_as_pdf_rounded
                      : Icons.file_upload_outlined,
                  color: colorScheme.onPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                hasSelection ? selectedFileName : 'Sube un PDF o EPUB',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                hasSelection
                    ? 'Toca para elegir otro archivo'
                    : 'Chatea con tus apuntes, obtén resúmenes\ny flashcards — todo en tu dispositivo',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.55),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pinta un borde punteado alrededor de un Container con esquinas
/// redondeadas. Flutter no tiene un BorderStyle.dashed nativo.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashGap;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    this.dashWidth = 6,
    this.dashGap = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final dashedPath = _createDashedPath(path, dashWidth, dashGap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashGap) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashGap;
        final next = math.min(distance + length, metric.length);
        if (draw) {
          dashedPath.addPath(
            metric.extractPath(distance, next),
            Offset.zero,
          );
        }
        distance = next;
        draw = !draw;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
