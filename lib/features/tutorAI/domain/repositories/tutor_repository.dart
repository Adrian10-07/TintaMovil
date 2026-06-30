import '../entities/chat_message.dart';
import '../entities/model_download_status.dart';

/// Contrato del repositorio del tutor IA.
///
/// La capa `presentation` solo conoce esta interfaz; nunca importa
/// nada de `data/`. Esto permite cambiar el LLM concreto (Gemma vs Qwen,
/// fllama vs llama_cpp, mock vs real) sin tocar la UI.
abstract class TutorRepository {
  /// Stream que emite el estado actual de la descarga/carga del modelo.
  ///
  /// La UI escucha esto para mostrar "Descargando 45%" o "Listo".
  /// La descarga se inicia con [ensureModelReady].
  Stream<ModelDownloadStatus> get downloadStatus;

  /// Verifica si el modelo está en disco. Si no, lo descarga.
  /// Si está, lo carga a memoria. Idempotente: llamarlo varias veces
  /// no descarga dos veces.
  ///
  /// La UI llama esto cuando el usuario entra por primera vez al chat.
  Future<void> ensureModelReady();

  /// Genera una respuesta del tutor a partir del historial completo.
  ///
  /// Devuelve un `Stream<String>` que emite tokens (palabras o sub-palabras)
  /// a medida que el modelo los genera. La UI los va concatenando para
  /// mostrar la respuesta apareciendo en tiempo real.
  ///
  /// El parámetro `documentContext` permite pasar el nombre del PDF que
  /// el usuario está leyendo, para que el modelo lo mencione si es relevante.
  Stream<String> generateResponse({
    required List<ChatMessage> history,
    String? documentContext,
  });

  /// Libera la memoria del modelo. Se llama cuando el usuario cierra
  /// la app o cuando hace mucho que no lo usa.
  Future<void> dispose();
}
