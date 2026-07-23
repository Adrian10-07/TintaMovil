import 'package:flutter/material.dart';

/// Diálogo para ingresar un código de invitación y unirse a un club privado.
class InviteDialog extends StatefulWidget {
  final Future<bool> Function(String code) onJoin;

  const InviteDialog({super.key, required this.onJoin});

  @override
  State<InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<InviteDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Ingresa un código de invitación.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await widget.onJoin(code);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Código inválido o expirado.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unirse con código'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ingresa el código de invitación que te compartieron.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Código',
              hintText: 'Ej: TINTA4XK',
              prefixIcon: const Icon(Icons.vpn_key_rounded),
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Unirse'),
        ),
      ],
    );
  }
}
