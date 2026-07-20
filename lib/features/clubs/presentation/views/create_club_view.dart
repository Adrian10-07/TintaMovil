import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/clubs_viewmodel.dart';
import 'club_detail_view.dart';

/// Pantalla para crear un nuevo club de lectura.
class CreateClubView extends StatefulWidget {
  const CreateClubView({super.key});

  @override
  State<CreateClubView> createState() => _CreateClubViewState();
}

class _CreateClubViewState extends State<CreateClubView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPrivate = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<ClubsViewModel>();
    final club = await vm.createClub(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      isPrivate: _isPrivate,
    );

    if (club != null && mounted) {
      // Navegar al detalle del club recién creado.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ClubDetailView(clubId: club.id)),
      );
    } else if (vm.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Crear club')),
      body: Consumer<ClubsViewModel>(
        builder: (_, vm, __) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Crea un espacio para discutir sobre tus libros favoritos.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nombre
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del club',
                      hintText: 'Ej: Amantes de la ciencia ficción',
                      prefixIcon: Icon(Icons.groups_rounded),
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 120,
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.length < 3) {
                        return 'El nombre debe tener al menos 3 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: '¿De qué trata este club?',
                      prefixIcon: Icon(Icons.description_rounded),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 16),

                  // Privacidad
                  SwitchListTile(
                    title: const Text('Club privado'),
                    subtitle: Text(
                      _isPrivate
                          ? 'Solo se puede unir con código de invitación.'
                          : 'Cualquiera puede encontrarlo y unirse.',
                      style: textTheme.bodySmall,
                    ),
                    secondary: Icon(
                      _isPrivate
                          ? Icons.lock_rounded
                          : Icons.public_rounded,
                    ),
                    value: _isPrivate,
                    onChanged: (v) => setState(() => _isPrivate = v),
                  ),

                  const SizedBox(height: 32),

                  // Botón de crear
                  FilledButton.icon(
                    onPressed: vm.isCreating ? null : _onSubmit,
                    icon: vm.isCreating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded),
                    label: Text(vm.isCreating ? 'Creando...' : 'Crear club'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
