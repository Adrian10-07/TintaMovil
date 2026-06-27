import 'package:flutter/material.dart';

/// Área de contenido del libro — muestra el texto de la página.
///
/// En una implementación real, esto renderizaría PDF/EPUB.
/// Por ahora simula el contenido de una página de texto.
class ReaderPageContent extends StatelessWidget {
  final int currentPage;
  final String? previewLink;

  const ReaderPageContent({
    Key? key,
    required this.currentPage,
    this.previewLink,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTapUp: (details) {
        final screenWidth = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < screenWidth / 2) {
          // TODO: Tap en la mitad izquierda
        } else {
          // TODO: Tap en la mitad derecha
        }
      },
      child: Container(
        color: colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Número de página sutil
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text(
                'Página $currentPage',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary.withOpacity(0.6),
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Divider decorativo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                color: colorScheme.primary.withOpacity(0.2),
                thickness: 1,
              ),
            ),
            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: _buildPageBody(context, colorScheme, textTheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageBody(
      BuildContext context,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    // Placeholder UI: muestra instrucciones hasta que integres tu visor de PDF/EPUB.
    // Reemplaza este widget con WebView, pdfx, flutter_pdfview, etc.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Integra aquí tu visor de PDF/EPUB (flutter_pdfview, pdfx, etc.)',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Texto simulado por página
        ...List.generate(8, (i) => _textParagraph(i, textTheme, colorScheme)),
      ],
    );
  }

  Widget _textParagraph(int i, TextTheme tt, ColorScheme cs) {
    final isHighlighted = i == 2; // Tercer párrafo resaltado (Memphis-style)
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: isHighlighted
          ? const EdgeInsets.all(12)
          : EdgeInsets.zero,
      decoration: isHighlighted
          ? BoxDecoration(
        color: cs.tertiary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: cs.tertiary, width: 3),
        ),
      )
          : null,
      child: Text(
        _sampleText(i),
        style: tt.bodyLarge?.copyWith(
          color: cs.onSurface,
          height: 1.8,
        ),
      ),
    );
  }

  String _sampleText(int i) {
    const paragraphs = [
      'Los hábitos son los intereses compuestos del autodesarrollo. Del mismo modo que el dinero se multiplica a través del interés compuesto, los efectos de tus hábitos se multiplican a medida que repites el día. El mismo modo de ver son pequeñas victorias o pequeñas pérdidas que se van acumulando.',
      'Si te vuelves un 1% mejor cada día durante un año, terminarás siendo 37 veces mejor al final. Por el contrario, si empeoraras un 1% cada día durante un año, casi llegarías a cero. Lo que empieza como una pequeña victoria o una pequeña pérdida se acumula hasta convertirse en algo mucho más.',
      '💡 «El tiempo magnifica el margen entre el éxito y el fracaso. Te multiplicará lo que sea que le introduzcas. Los buenos hábitos hacen que el tiempo se convierta en tu aliado. Los malos hábitos hacen que el tiempo se convierta en tu enemigo.»',
      'Por eso es tan importante dominar los hábitos fundamentales de tu campo. En el largo plazo, la calidad de tu vida suele ser función de la calidad de tus hábitos. Con los mismos hábitos, obtendrás siempre los mismos resultados.',
      'Esto también significa que no podemos continuar viviendo del mismo modo y esperando resultados distintos. Cuando tus comportamientos predeterminados te conducen hasta donde quieres ir, no hay necesidad de hacer ningún cambio.',
      'Pero a menudo nos encontramos atrapados en bucles de retroalimentación poco saludables. Pasamos de la gratificación inmediata al arrepentimiento y de vuelta al principio. Nuestros hábitos parecen tan arraigados que es difícil imaginar que puedan cambiar.',
      'La alternativa es construir mejores hábitos. No mediante la fuerza de voluntad, sino mediante el diseño inteligente de nuestro entorno y rutinas. El objetivo es hacer que las acciones correctas sean tan sencillas que resulte más fácil hacerlas bien que hacerlas mal.',
      'Cuando comprendes que los hábitos son el mecanismo mediante el cual experimentas el mundo, empiezas a ver el potencial de cambio que tienes en tus manos cada día.',
    ];
    return paragraphs[i % paragraphs.length];
  }
}
