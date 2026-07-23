import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:tinta/core/di/service_locator.dart';

import '../../data/datasources/tts_service.dart';
import '../../domain/entities/chat_message.dart';

/// Fila de acciones de audio debajo de cada burbuja del asistente.
///
/// Tres estados visuales:
///   1. **Sin audio**: muestra [Escuchar] y [Guardar audio].
///   2. **Generando**: muestra spinner en el chip de guardar.
///   3. **Audio guardado**: muestra un mini reproductor con play/pause,
///      barra de progreso y duración — persistente mientras exista el .wav.
class TtsMessageActions extends StatefulWidget {
  final ChatMessage message;

  const TtsMessageActions({super.key, required this.message});

  @override
  State<TtsMessageActions> createState() => _TtsMessageActionsState();
}

class _TtsMessageActionsState extends State<TtsMessageActions> {
  final TtsService _tts = sl<TtsService>();
  StreamSubscription<TtsStatus>? _ttsSub;

  // ── Estado del TTS (hablar en vivo) ─────────────────────────────
  TtsPlaybackState _ttsState = TtsPlaybackState.idle;
  String? _activeTtsId;

  // ── Estado del archivo guardado ─────────────────────────────────
  String? _savedFilePath;
  bool _isSynthesizing = false;
  bool _checkingCache = true;

  // ── Reproductor de archivo ──────────────────────────────────────
  AudioPlayer? _player;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _checkExistingAudio();
    _syncFromStatus(_tts.lastStatus);
    _ttsSub = _tts.statusStream.listen(_syncFromStatus);
  }

  /// Al montar, verifica si ya existe un archivo en disco para este mensaje.
  Future<void> _checkExistingAudio() async {
    final path = await _tts.getAudioPath(widget.message.id);
    if (mounted) {
      setState(() {
        _savedFilePath = path;
        _checkingCache = false;
      });
    }
  }

  void _syncFromStatus(TtsStatus status) {
    if (!mounted) return;
    setState(() {
      _ttsState = status.state;
      _activeTtsId = status.activeMessageId;
      if (status.state == TtsPlaybackState.synthesizing &&
          status.activeMessageId == widget.message.id) {
        _isSynthesizing = true;
      }
      if (status.state != TtsPlaybackState.synthesizing &&
          _activeTtsId == widget.message.id) {
        _isSynthesizing = false;
      }
    });
  }

  @override
  void dispose() {
    _ttsSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  // ── Helpers de estado ───────────────────────────────────────────

  bool get _isThisMessageActive => _activeTtsId == widget.message.id;

  bool get _isSpeakingLive =>
      _ttsState == TtsPlaybackState.speaking && _isThisMessageActive;

  bool get _isAnyTtsBusy =>
      _ttsState == TtsPlaybackState.speaking ||
          _ttsState == TtsPlaybackState.synthesizing;

  bool get _hasAudio => _savedFilePath != null;

  bool get _isFilePlaying => _playerState == PlayerState.playing;

  // ── Acciones ────────────────────────────────────────────────────

  Future<void> _handleSpeakLive() async {
    // Si el reproductor de archivo está sonando, pausarlo primero.
    if (_isFilePlaying) {
      await _player?.pause();
    }

    if (_isSpeakingLive) {
      await _tts.stop();
    } else {
      await _tts.speak(
        widget.message.content,
        messageId: widget.message.id,
      );
    }
  }

  Future<void> _handleSaveAudio() async {
    try {
      final path = await _tts.synthesizeToFile(
        widget.message.content,
        messageId: widget.message.id,
      );
      if (mounted) {
        setState(() => _savedFilePath = path);
        _initPlayerIfNeeded();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Audio guardado correctamente'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  // ── Reproductor de archivo ──────────────────────────────────────

  void _initPlayerIfNeeded() {
    if (_player != null || _savedFilePath == null) return;

    _player = AudioPlayer();

    _stateSub = _player!.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });

    _durSub = _player!.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });

    _posSub = _player!.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
  }

  Future<void> _toggleFilePlayback() async {
    if (_savedFilePath == null) return;

    // Si el TTS en vivo está sonando, detenerlo primero.
    if (_isSpeakingLive) {
      await _tts.stop();
    }

    _initPlayerIfNeeded();

    if (_isFilePlaying) {
      await _player!.pause();
    } else {
      await _player!.play(DeviceFileSource(_savedFilePath!));
    }
  }

  Future<void> _seekTo(double value) async {
    if (_player == null || _duration == Duration.zero) return;
    final pos = Duration(
      milliseconds: (value * _duration.inMilliseconds).round(),
    );
    await _player!.seek(pos);
  }

  // ── Formateo de duración ────────────────────────────────────────

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  // ── UI ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (widget.message.content.isEmpty || widget.message.isStreaming) {
      return const SizedBox.shrink();
    }

    if (_checkingCache) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Fila de chips ───────────────────────────────────────
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón Escuchar en vivo / Detener
              _ActionChip(
                icon: _isSpeakingLive
                    ? Icons.stop_rounded
                    : Icons.volume_up_rounded,
                label: _isSpeakingLive ? 'Detener' : 'Escuchar',
                isActive: _isSpeakingLive,
                isLoading: false,
                isDisabled: _isAnyTtsBusy && !_isSpeakingLive,
                onTap: _handleSpeakLive,
              ),
              const SizedBox(width: 8),

              // Botón Guardar audio
              if (!_hasAudio)
                _ActionChip(
                  icon: Icons.download_rounded,
                  label: _isSynthesizing ? 'Generando…' : 'Guardar audio',
                  isActive: false,
                  isLoading: _isSynthesizing,
                  isDisabled: _isAnyTtsBusy || _isSynthesizing,
                  onTap: _handleSaveAudio,
                ),

              // Badge "Guardado" cuando ya existe el archivo
              if (_hasAudio)
                _ActionChip(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Audio guardado',
                  isActive: false,
                  isLoading: false,
                  isDisabled: false,
                  // Tap para resaltar el mini player.
                  onTap: _hasAudio ? _toggleFilePlayback : null,
                ),
            ],
          ),

          // ── Mini reproductor (solo si hay audio guardado) ───────
          if (_hasAudio) _buildMiniPlayer(context),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play / Pause del archivo.
            GestureDetector(
              onTap: _toggleFilePlayback,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isFilePlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: cs.onPrimary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Barra de progreso + tiempos.
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Slider de progreso.
                  SizedBox(
                    height: 16,
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 5,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                        activeTrackColor: cs.primary,
                        inactiveTrackColor: cs.onSurfaceVariant.withOpacity(0.2),
                        thumbColor: cs.primary,
                      ),
                      child: Slider(
                        value: progress,
                        onChanged: _seekTo,
                      ),
                    ),
                  ),

                  // Tiempos.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_position),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 10,
                              color: cs.onSurfaceVariant.withOpacity(0.5),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Offline',
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant.withOpacity(0.5),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatDuration(_duration),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip reutilizable para acciones de TTS.
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final bgColor = isActive ? cs.primary : cs.surfaceContainerHigh;
    final fgColor = isActive
        ? cs.onPrimary
        : isDisabled
        ? cs.onSurfaceVariant.withOpacity(0.4)
        : cs.onSurfaceVariant;

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: fgColor,
                  ),
                )
              else
                Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}