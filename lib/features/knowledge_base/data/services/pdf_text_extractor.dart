import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as syncfusion;

/// Resultado de extracción de texto de una página.
class PageText {
  final int pageNumber;
  final String text;

  const PageText({required this.pageNumber, required this.text});
}

/// Función auxiliar de nivel superior para ejecutarse en el Isolate de segundo plano.
///
/// Esto previene el bloqueo del hilo de la interfaz de usuario (UI thread)
/// durante el procesamiento pesado del PDF.
Future<List<PageText>> _extractTextInBackground(String filePath) async {
  final file = File(filePath);
  final bytes = await file.readAsBytes();

  final document = syncfusion.PdfDocument(inputBytes: bytes);
  final pages = <PageText>[];

  try {
    for (int i = 0; i < document.pages.count; i++) {
      final extractor = syncfusion.PdfTextExtractor(document);
      final text = extractor.extractText(startPageIndex: i, endPageIndex: i);

      if (text.trim().isNotEmpty) {
        pages.add(PageText(pageNumber: i + 1, text: text.trim()));
      }
    }
  } finally {
    document.dispose();
  }

  return pages;
}

/// Servicio que extrae texto crudo de un PDF página por página.
///
/// Usa Syncfusion Flutter PDF en un Isolate secundario para no congelar la app.
class PdfTextExtractor {
  /// Extrae el texto de todas las páginas del PDF.
  ///
  /// Devuelve una lista de [PageText] ordenada por número de página.
  /// Las páginas sin texto (imágenes puras) se omiten.
  Future<List<PageText>> extractText(String filePath) async {
    return compute(_extractTextInBackground, filePath);
  }
}
