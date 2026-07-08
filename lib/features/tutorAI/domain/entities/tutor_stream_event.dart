import 'tutor_source.dart';

/// Evento emitido por el stream de generación del tutor.
///
/// Un stream de respuesta emite muchos [TokenEvent] durante la generación
/// y termina con un [DoneEvent] que contiene las fuentes citadas.
sealed class TutorStreamEvent {
  const TutorStreamEvent();
}

/// Un token nuevo generado por el LLM. La UI lo concatena al mensaje actual.
class TokenEvent extends TutorStreamEvent {
  final String token;
  const TokenEvent(this.token);
}

/// Fin de la generación. Incluye las fuentes citadas (vacío si no hubo RAG).
class DoneEvent extends TutorStreamEvent {
  final List<TutorSource> sources;
  const DoneEvent({this.sources = const []});
}

/// Error durante la generación. La UI muestra un mensaje y detiene el stream.
class ErrorEvent extends TutorStreamEvent {
  final String message;
  const ErrorEvent(this.message);
}
