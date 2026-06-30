/// Estado de la descarga del modelo Gemma desde HuggingFace.
///
/// Se usa para que la UI muestre una barra de progreso "Descargando tutor IA…"
/// la primera vez que el usuario abre el chat.
///
/// El modelo (~1.5 GB) se descarga UNA sola vez y se guarda en el
/// almacenamiento interno de la app. Las siguientes veces se carga desde
/// disco sin internet.
class ModelDownloadStatus {
  final ModelDownloadStage stage;
  final int bytesDownloaded;
  final int totalBytes;
  final String? errorMessage;

  const ModelDownloadStatus({
    required this.stage,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.errorMessage,
  });

  /// Progreso de 0.0 a 1.0. Devuelve 0 si aún no se conoce el tamaño total.
  double get progress {
    if (totalBytes == 0) return 0;
    return bytesDownloaded / totalBytes;
  }

  /// "523 MB / 1.5 GB" - formato amigable para la UI.
  String get formattedProgress {
    final mbDown = (bytesDownloaded / 1024 / 1024).toStringAsFixed(0);
    final mbTotal = (totalBytes / 1024 / 1024).toStringAsFixed(0);
    return '$mbDown MB / $mbTotal MB';
  }

  bool get isReady => stage == ModelDownloadStage.ready;
  bool get isFailed => stage == ModelDownloadStage.failed;
  bool get isInProgress =>
      stage == ModelDownloadStage.downloading ||
      stage == ModelDownloadStage.loading;
}

enum ModelDownloadStage {
  /// Aún no se ha intentado nada (estado inicial).
  idle,

  /// Verificando si el archivo ya existe en disco local.
  checking,

  /// Bajando el .gguf desde HuggingFace.
  downloading,

  /// Cargando el modelo desde disco a memoria (puede tardar 5-20s).
  loading,

  /// Listo para usar.
  ready,

  /// Algo salió mal (sin internet, espacio insuficiente, etc.).
  failed,
}
