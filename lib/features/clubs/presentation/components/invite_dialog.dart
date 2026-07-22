import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../domain/entities/club.dart';
import '../../domain/repositories/club_repository.dart';

/// Diálogo para unirse a un club privado ingresando el ID del club.
///
/// Flujo: pega el ID → muestra preview del club → confirma → join.
class InviteDialog extends StatefulWidget {
  final Future<bool> Function(String clubId) onJoin;

  const InviteDialog({super.key, required this.onJoin});

  @override
  State<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<InviteDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  bool _isJoining = false;
  String? _error;
  Club? _previewClub;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Paso 1: buscar el club por ID para mostrar preview.
  Future<void> _search() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() => _error = 'Pega el código del club.');
      return;
    }

    setState(() { _isLoading = true; _error = null; _previewClub = null; });

    try {
      final repo = sl<ClubRepository>();
      final club = await repo.getClub(input);
      setState(() { _previewClub = club; _isLoading = false; });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = 'No se encontró ningún club con ese código.';
      });
    }
  }

  /// Paso 2: unirse al club.
  Future<void> _join() async {
    if (_previewClub == null) return;
    setState(() { _isJoining = true; _error = null; });

    final success = await widget.onJoin(_previewClub!.id);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() {
          _isJoining = false;
          _error = 'No se pudo unir al club.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Unirse a un club'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pega el código que te compartió el administrador del club.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Input
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Código del club',
              hintText: 'Ej: a1b2c3d4-e5f6-...',
              prefixIcon: const Icon(Icons.vpn_key_rounded),
              border: const OutlineInputBorder(),
              errorText: _error,
              suffixIcon: _isLoading
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: _search,
              ),
            ),
            onSubmitted: (_) => _search(),
          ),

          // Preview del club
          if (_previewClub != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      _previewClub!.name.isNotEmpty
                          ? _previewClub!.name[0].toUpperCase() : '?',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_previewClub!.name, style: textTheme.titleSmall),
                        if (_previewClub!.description.isNotEmpty)
                          Text(
                            _previewClub!.description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Row(
                          children: [
                            Icon(
                              _previewClub!.isPrivate
                                  ? Icons.lock_rounded : Icons.public_rounded,
                              size: 12, color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _previewClub!.isPrivate ? 'Privado' : 'Público',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_rounded,
                      color: colorScheme.primary, size: 24),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: (_isLoading || _isJoining) ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (_previewClub != null)
          FilledButton.icon(
            onPressed: _isJoining ? null : _join,
            icon: _isJoining
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.group_add_rounded, size: 18),
            label: Text(_isJoining ? 'Uniéndose...' : 'Unirse'),
          )
        else
          FilledButton(
            onPressed: _isLoading ? null : _search,
            child: Text(_isLoading ? 'Buscando...' : 'Buscar'),
          ),
      ],
    );
  }
}
