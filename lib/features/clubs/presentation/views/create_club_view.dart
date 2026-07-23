import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../home/domain/entities/book.dart';
import '../../../home/domain/repositories/book_repository.dart';
import '../viewmodels/clubs_viewmodel.dart';
import 'club_chat_view.dart';

/// Categorías predefinidas para clubes.
const _clubCategories = [
  'Ficción',
  'Ciencia',
  'Filosofía',
  'Historia',
  'Tecnología',
  'Arte',
  'Psicología',
  'Negocios',
  'Autoayuda',
  'Otro',
];

/// Pantalla para crear un nuevo club con opciones enriquecidas.
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
  String? _selectedCategory;
  Book? _selectedBook;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickBook() async {
    final book = await showModalBottomSheet<Book>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _BookPickerSheet(),
    );
    if (book != null) {
      setState(() {
        _selectedBook = book;
        // Auto-rellenar nombre y categoría si están vacíos.
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = 'Club: ${book.title}';
        }
        _selectedCategory ??= book.category;
      });
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final vm = context.read<ClubsViewModel>();

    // Los libros del catálogo local usan slugs como ID ("mary-shelley_frankenstein"),
    // no UUIDs. El backend espera UUID para book_id, así que incluimos el título
    // del libro en la descripción en lugar de enviar un book_id inválido.
    var description = _descriptionController.text.trim();
    if (_selectedBook != null) {
      final bookInfo = '📖 ${_selectedBook!.title} — ${_selectedBook!.authors.join(', ')}';
      description = description.isEmpty ? bookInfo : '$bookInfo\n\n$description';
    }

    final club = await vm.createClub(
      name: _nameController.text.trim(),
      description: description,
      category: _selectedCategory,
      isPrivate: _isPrivate,
    );

    if (club != null && mounted) {
      // Navegar directo al chat del club recién creado.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClubChatView(
            clubId: club.id,
            clubName: club.name,
            memberCount: 1,
            isCreator: true,
          ),
        ),
      );
    } else if (vm.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                    'Crea un espacio para discutir sobre tus libros favoritos con personas afines.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Libro asociado ──
                  Text('Libro (opcional)', style: textTheme.labelLarge),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickBook,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _selectedBook != null
                          ? Row(
                        children: [
                          if (_selectedBook!.thumbnailUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                _selectedBook!.thumbnailUrl!,
                                width: 40,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                const Icon(Icons.book_rounded),
                              ),
                            )
                          else
                            Icon(Icons.book_rounded,
                                color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedBook!.title,
                                    style: textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                Text(
                                  _selectedBook!.authors.join(', '),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () =>
                                setState(() => _selectedBook = null),
                          ),
                        ],
                      )
                          : Row(
                        children: [
                          Icon(Icons.add_rounded,
                              color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text('Seleccionar un libro del catálogo',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Nombre ──
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del club',
                      hintText: 'Ej: Amantes de la ciencia ficción',
                      prefixIcon: Icon(Icons.groups_rounded),
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 120,
                    validator: (v) {
                      if ((v?.trim() ?? '').length < 3) {
                        return 'Al menos 3 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // ── Descripción ──
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: '¿De qué trata este club?',
                      prefixIcon: Icon(Icons.description_rounded),
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 12),

                  // ── Categoría ──
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: _clubCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
                  const SizedBox(height: 16),

                  // ── Privacidad ──
                  SwitchListTile(
                    title: const Text('Club privado'),
                    subtitle: Text(
                      _isPrivate
                          ? 'Solo con código de invitación del admin.'
                          : 'Cualquiera puede encontrarlo y unirse.',
                      style: textTheme.bodySmall,
                    ),
                    secondary: Icon(
                      _isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                    ),
                    value: _isPrivate,
                    onChanged: (v) => setState(() => _isPrivate = v),
                  ),
                  const SizedBox(height: 32),

                  // ── Botón crear ──
                  FilledButton.icon(
                    onPressed: vm.isCreating ? null : _onSubmit,
                    icon: vm.isCreating
                        ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
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

/// Bottom sheet para seleccionar un libro del catálogo.
class _BookPickerSheet extends StatefulWidget {
  const _BookPickerSheet();

  @override
  State<_BookPickerSheet> createState() => _BookPickerSheetState();
}

class _BookPickerSheetState extends State<_BookPickerSheet> {
  List<Book> _books = [];
  List<Book> _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    try {
      final repo = sl<BookRepository>();
      _books = await repo.getBooksCatalog();
      _filtered = _books;
    } catch (_) {}
    _loading = false;
    if (mounted) setState(() {});
  }

  void _filter(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _books
          : _books.where((b) =>
      b.title.toLowerCase().contains(q) ||
          b.authors.any((a) => a.toLowerCase().contains(q))).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SearchBar(
                controller: _searchController,
                hintText: 'Buscar libro...',
                leading: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                onChanged: _filter,
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor:
                WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                  ? const Center(child: Text('No se encontraron libros.'))
                  : ListView.builder(
                controller: controller,
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final book = _filtered[i];
                  return ListTile(
                    leading: book.thumbnailUrl != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        book.thumbnailUrl!,
                        width: 36, height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                        const Icon(Icons.book_rounded),
                      ),
                    )
                        : const Icon(Icons.book_rounded),
                    title: Text(book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    subtitle: Text(book.authors.join(', '),
                        maxLines: 1),
                    onTap: () => Navigator.pop(context, book),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}