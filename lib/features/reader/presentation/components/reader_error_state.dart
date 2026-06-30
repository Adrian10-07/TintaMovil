import 'package:flutter/material.dart';

/// Pantalla de error al fallar la descarga/apertura del EPUB.
/// Muestra un mensaje amigable arriba, y el detalle técnico completo
/// (útil mientras depuras) en un panel colapsable aparte.
class ReaderErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const ReaderErrorState({
    Key? key,
    required this.errorMessage,
    required this.onRetry,
    required this.onBack,
  }) : super(key: key);

  /// Extrae solo la primera línea legible del error, para mostrarla
  /// como mensaje principal. El resto (URLs, content-type, preview)
  /// se manda al panel de detalle técnico.
  String get _friendlyMessage {
    final firstLine = errorMessage.split('\n').first;
    if (firstLine.length > 120) {
      return 'No se pudo descargar el libro.';
    }
    return firstLine;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              _friendlyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            _TechnicalDetailPanel(fullMessage: errorMessage),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Volver'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TechnicalDetailPanel extends StatefulWidget {
  final String fullMessage;
  const _TechnicalDetailPanel({required this.fullMessage});

  @override
  State<_TechnicalDetailPanel> createState() => _TechnicalDetailPanelState();
}

class _TechnicalDetailPanelState extends State<_TechnicalDetailPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(
            _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            size: 18,
          ),
          label: Text(_expanded ? 'Ocultar detalle' : 'Ver detalle técnico'),
        ),
        if (_expanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              widget.fullMessage,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: colorScheme.onSurface.withOpacity(0.65),
              ),
            ),
          ),
      ],
    );
  }
}