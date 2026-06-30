/// Entidad pura: tema académico del tutor IA.
///
/// Para esta versión MVP solo existen 2 temas:
///   - Programación e informática
///   - Historia
///
/// Los temas se eligen al crear la cuenta (en otra feature, no aquí).
/// Esta clase es inmutable y se expone como constantes estáticas.
class TutorTopic {
  final String id;
  final String slug;
  final String name;
  final String description;

  const TutorTopic({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
  });

  // ── Temas disponibles para el MVP ──────────────────────────────────
  static const programming = TutorTopic(
    id: 'topic-programming',
    slug: 'programacion',
    name: 'Programación e Informática',
    description: 'Algoritmos, lenguajes de programación y sistemas.',
  );

  static const history = TutorTopic(
    id: 'topic-history',
    slug: 'historia',
    name: 'Historia',
    description: 'Historia universal, de México y de la cultura.',
  );

  static const List<TutorTopic> all = [programming, history];
}
