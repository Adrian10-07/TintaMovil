import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

/// Estados posibles del TTS.
enum TtsPlaybackState { idle, speaking, synthesizing, error }

/// Evento emitido por [TtsService] para que la UI reaccione.
class TtsStatus {
  final TtsPlaybackState state;
  final String? activeMessageId;
  final String? error;

  const TtsStatus({
    required this.state,
    this.activeMessageId,
    this.error,
  });

  const TtsStatus.idle()
      : state = TtsPlaybackState.idle,
        activeMessageId = null,
        error = null;
}

/// Servicio singleton que encapsula `flutter_tts`.
///
/// Provee tres funcionalidades:
///   1. **Reproducir en vivo** (`speak`): lee el texto con el motor nativo.
///   2. **Sintetizar a archivo** (`synthesizeToFile`): genera un `.wav`
///      persistente en disco para escucha offline.
///   3. **Caché de archivos** (`getAudioPath`): consulta si un mensaje
///      ya tiene audio generado para que la UI lo muestre de inmediato.
///
/// Registrado como lazySingleton en el service locator.
class TtsService {
  final FlutterTts _tts = FlutterTts();

  final StreamController<TtsStatus> _statusController =
  StreamController<TtsStatus>.broadcast();

  Stream<TtsStatus> get statusStream => _statusController.stream;

  TtsStatus _lastStatus = const TtsStatus.idle();
  TtsStatus get lastStatus => _lastStatus;

  /// Caché en memoria: messageId → ruta absoluta del .wav generado.
  /// Persiste durante la vida del singleton (toda la sesión de la app).
  final Map<String, String> _audioCache = {};

  bool _initialized = false;

  // ── Inicialización ──────────────────────────────────────────────────

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    // ⚠️ CLAVE: sin esto, synthesizeToFile retorna inmediatamente
    // sin esperar a que el motor nativo termine de escribir el archivo.
    await _tts.awaitSynthCompletion(true);
    await _tts.awaitSpeakCompletion(true);

    // Idioma: español latinoamericano con fallback.
    final languages = await _tts.getLanguages as List<dynamic>;
    if (languages.contains('es-MX')) {
      await _tts.setLanguage('es-MX');
    } else if (languages.contains('es-US')) {
      await _tts.setLanguage('es-US');
    } else {
      await _tts.setLanguage('es-ES');
    }

    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      _emit(TtsStatus(
        state: TtsPlaybackState.speaking,
        activeMessageId: _lastStatus.activeMessageId,
      ));
    });

    _tts.setCompletionHandler(() {
      _emit(const TtsStatus.idle());
    });

    _tts.setCancelHandler(() {
      _emit(const TtsStatus.idle());
    });

    _tts.setErrorHandler((msg) {
      _emit(TtsStatus(
        state: TtsPlaybackState.error,
        error: msg.toString(),
        activeMessageId: _lastStatus.activeMessageId,
      ));
    });

    _initialized = true;
  }

  void _emit(TtsStatus status) {
    _lastStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  // ── Directorio de audio ─────────────────────────────────────────────

  Future<Directory> _audioDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/tinta_audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  String _safeFileName(String messageId) {
    return 'tutor_${messageId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}.wav';
  }

  // ── Consulta de caché ───────────────────────────────────────────────

  /// Retorna la ruta del audio si ya existe para este mensaje, null si no.
  /// Consulta primero el caché en memoria, luego el disco.
  Future<String?> getAudioPath(String messageId) async {
    // 1. Caché en memoria.
    if (_audioCache.containsKey(messageId)) {
      final path = _audioCache[messageId]!;
      final file = File(path);
      if (await file.exists() && await file.length() > 100) {
        return path;
      }
      _audioCache.remove(messageId);
    }

    // 2. Buscar en disco.
    try {
      final dir = await _audioDir();
      final fileName = _safeFileName(messageId);
      final file = File('${dir.path}/$fileName');
      if (await file.exists() && await file.length() > 100) {
        _audioCache[messageId] = file.path;
        return file.path;
      }
    } catch (_) {}

    return null;
  }

  // ── Limpieza de markdown ──────────────────────────────────────────

  /// Limpia el texto de markdown y símbolos para que el TTS lea solo
  /// texto natural. Enfoque simple: eliminar los caracteres problemáticos
  /// directamente en vez de parsear markdown con regex frágiles.
  String _cleanForSpeech(String text) {
    var clean = text;

    // 1. Bloques de código completos → omitir su contenido
    clean = clean.replaceAll(RegExp(r'```[\s\S]*?```'), '. ');

    // 2. Código inline: `texto` → solo el texto
    clean = clean.replaceAll(RegExp(r'`([^`]+)`'), r'$1');

    // 3. Links: [texto](url) → solo el texto visible
    clean = clean.replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1');

    // 4. Imágenes: ![alt](url) → omitir
    clean = clean.replaceAll(RegExp(r'!\[([^\]]*)\]\([^\)]+\)'), '');

    // 5. Eliminar TODOS los caracteres que el TTS lee mal.
    //    Esto es lo que resuelve el problema de los asteriscos.
    clean = clean.replaceAll('*', '');
    clean = clean.replaceAll('#', '');
    clean = clean.replaceAll('~', '');
    clean = clean.replaceAll('|', '');
    clean = clean.replaceAll('>', '');
    clean = clean.replaceAll('`', '');
    clean = clean.replaceAll('\$', '');
    clean = clean.replaceAll('\\', '');

    // 6. Listas con guión al inicio de línea: - item → item
    clean = clean.replaceAll(RegExp(r'^\s*-\s+', multiLine: true), '');

    // 7. Listas numeradas: 1. item → item
    clean = clean.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');

    // 8. Líneas horizontales (---, ___) → pausa
    clean = clean.replaceAll(RegExp(r'^[\-_]{3,}\s*$', multiLine: true), '. ');

    // 9. Múltiples saltos de línea → uno solo
    clean = clean.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // 10. Espacios múltiples → uno solo
    clean = clean.replaceAll(RegExp(r' {2,}'), ' ');

    return clean.trim();
  }

  // ── Reproducción en vivo ────────────────────────────────────────────

  Future<void> speak(String text, {required String messageId}) async {
    await _ensureInitialized();

    if (_lastStatus.state == TtsPlaybackState.speaking) {
      await stop();
    }

    _emit(TtsStatus(
      state: TtsPlaybackState.speaking,
      activeMessageId: messageId,
    ));

    await _tts.speak(_cleanForSpeech(text));
  }

  Future<void> stop() async {
    await _tts.stop();
    _emit(const TtsStatus.idle());
  }

  // ── Síntesis a archivo ──────────────────────────────────────────────

  /// Genera un `.wav` y retorna su ruta absoluta.
  ///
  /// En Android se usa solo el nombre del archivo (el motor lo guarda en
  /// su directorio de datos). En iOS se pasa la ruta completa.
  /// El tercer parámetro `isFullPath` indica si se usa ruta absoluta.
  Future<String> synthesizeToFile(
      String text, {
        required String messageId,
      }) async {
    await _ensureInitialized();

    // Verificar caché primero.
    final cached = await getAudioPath(messageId);
    if (cached != null) return cached;

    _emit(TtsStatus(
      state: TtsPlaybackState.synthesizing,
      activeMessageId: messageId,
    ));

    try {
      final dir = await _audioDir();
      final fileName = _safeFileName(messageId);
      final fullPath = '${dir.path}/$fileName';

      // Limpiar archivo previo roto si existiera.
      final existing = File(fullPath);
      if (await existing.exists()) {
        await existing.delete();
      }

      // ── Llamar synthesizeToFile ──────────────────────────────────
      // Android: usar solo el nombre del archivo (el motor lo guarda
      //   en /storage/emulated/0/Android/data/<pkg>/files/).
      // iOS: usar la ruta completa.
      //
      // awaitSynthCompletion(true) hace que este await espere
      // REALMENTE hasta que el archivo esté escrito en disco.
      if (Platform.isAndroid) {
        await _tts.synthesizeToFile(_cleanForSpeech(text), fileName);
      } else {
        await _tts.synthesizeToFile(_cleanForSpeech(text), fullPath);
      }

      // ── Localizar el archivo generado ────────────────────────────
      // En Android, el motor TTS escribe en su propio directorio.
      // Buscamos el archivo ahí y lo copiamos a nuestro directorio.
      String finalPath = fullPath;

      if (Platform.isAndroid) {
        // El motor TTS de Android guarda en:
        //   /storage/emulated/0/Android/data/<pkg>/files/<fileName>
        // o en el directorio externo de la app.
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final ttsFile = File('${externalDir.path}/$fileName');
          if (await ttsFile.exists() && await ttsFile.length() > 100) {
            // Copiar a nuestro directorio de audio.
            await ttsFile.copy(fullPath);
            await ttsFile.delete();
            finalPath = fullPath;
          }
        }

        // Fallback: verificar si el archivo está directamente en fullPath.
        final directFile = File(fullPath);
        if (!await directFile.exists() || await directFile.length() <= 100) {
          // Último intento: buscar en el directorio de documentos.
          final docsDir = await getApplicationDocumentsDirectory();
          final altFile = File('${docsDir.path}/$fileName');
          if (await altFile.exists() && await altFile.length() > 100) {
            if (altFile.path != fullPath) {
              await altFile.copy(fullPath);
            }
            finalPath = fullPath;
          }
        }
      }

      // Verificar que el archivo final existe.
      final finalFile = File(finalPath);
      if (!await finalFile.exists() || await finalFile.length() <= 100) {
        throw Exception(
          'El motor TTS no generó el archivo de audio. '
              'Verifica que Google TTS esté instalado en el dispositivo.',
        );
      }

      // Guardar en caché.
      _audioCache[messageId] = finalPath;

      _emit(const TtsStatus.idle());

      return finalPath;
    } catch (e) {
      _emit(TtsStatus(
        state: TtsPlaybackState.error,
        activeMessageId: messageId,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  // ── Utilidades ──────────────────────────────────────────────────────

  Future<bool> isAvailable() async {
    try {
      await _ensureInitialized();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Elimina todos los archivos de audio generados.
  Future<void> clearCache() async {
    _audioCache.clear();
    try {
      final dir = await _audioDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _statusController.close();
  }
}