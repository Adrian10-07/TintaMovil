/// Metadata de una base de conocimiento descargable para el LLM local
/// (Tinta AI / Qwen vía llama_cpp_dart).
///
/// El MVP solo tiene 2 disponibles; el catálogo está pensado para poder
/// agregar más en el futuro sin tocar la lógica de la encuesta.
class KnowledgeBaseOption {
  final String id;
  final String title;
  final String description;
  final String assetPath;
  final String conceptCountLabel;

  const KnowledgeBaseOption({
    required this.id,
    required this.title,
    required this.description,
    required this.assetPath,
    required this.conceptCountLabel,
  });
}

/// Catálogo estático de bases de conocimiento disponibles en el MVP.
class KnowledgeBaseCatalog {
  static const List<KnowledgeBaseOption> available = [
    KnowledgeBaseOption(
      id: 'kb_programacion_informatica',
      title: 'Programación e Informática',
      description:
      'Fundamentos de informática, algoritmos, estructuras de datos, '
          'bases de datos, redes, paradigmas, IA y seguridad.',
      assetPath: 'assets/data/kb_programacion_informatica.md',
      conceptCountLabel: '109 conceptos',
    ),
    KnowledgeBaseOption(
      id: 'kb_historia',
      title: 'Historia',
      description:
      'Prehistoria, primeras civilizaciones, las cuatro edades '
          'históricas e historia de México.',
      assetPath: 'assets/data/kb_historia.md',
      conceptCountLabel: '88 conceptos',
    ),
  ];
}