import 'package:flutter/material.dart';

/// Bottom sheet para editar nombre e idioma del usuario.
///
/// Campos editables según el backend (PATCH /users/me):
///   name, avatar_url, language
class EditProfileSheet extends StatefulWidget {
  final String currentName;
  final String currentLanguage;
  final Future<bool> Function({String? name, String? language}) onSave;

  const EditProfileSheet({
    Key? key,
    required this.currentName,
    required this.currentLanguage,
    required this.onSave,
  }) : super(key: key);

  static Future<void> show(
      BuildContext context, {
        required String currentName,
        required String currentLanguage,
        required Future<bool> Function({String? name, String? language}) onSave,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditProfileSheet(
        currentName: currentName,
        currentLanguage: currentLanguage,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameController;
  late String _selectedLanguage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _selectedLanguage = widget.currentLanguage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final name = _nameController.text.trim();
    if (name.length < 2) return;

    setState(() => _isSaving = true);

    final success = await widget.onSave(
      name: name != widget.currentName ? name : null,
      language: _selectedLanguage != widget.currentLanguage
          ? _selectedLanguage
          : null,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Editar perfil', style: textTheme.headlineSmall),
          const SizedBox(height: 24),

          // Nombre
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 16),

          // Idioma (selector)
          Text('Idioma', style: textTheme.labelMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              _LanguageChip(
                label: '🇲🇽 Español',
                selected: _selectedLanguage == 'es',
                onTap: () => setState(() => _selectedLanguage = 'es'),
              ),
              const SizedBox(width: 12),
              _LanguageChip(
                label: '🇺🇸 English',
                selected: _selectedLanguage == 'en',
                onTap: () => setState(() => _selectedLanguage = 'en'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Botón guardar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _onSave,
              child: _isSaving
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
                  : const Text('Guardar cambios'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}