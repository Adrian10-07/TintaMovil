import 'package:flutter/material.dart';
import '../viewmodels/home_viewmodel.dart';

class HomeView extends StatefulWidget {
  final HomeViewModel viewModel;
  final String defaultQuery;

  const HomeView({
    Key? key,
    required this.viewModel,
    required this.defaultQuery,
  }) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final ScrollController _scrollController = ScrollController();

  // ── Paleta Tinta ──────────────────────────────────────────────
  static const _mintPrimary    = Color(0xFF3DBF7A);
  static const _deepGreen      = Color(0xFF1A4D2E);
  static const _pistachioLight = Color(0xFFC8EDD8);
  static const _warmGold       = Color(0xFFF5C842);
  static const _peach          = Color(0xFFFFBF9B);
  static const _offWhite       = Color(0xFFF2F5EF);
  static const _darkText       = Color(0xFF1A2B1F);
  static const _coral          = Color(0xFFFF7E7E);

  // ── Estado UI ─────────────────────────────────────────────────
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.viewModel.loadInitialCatalog(widget.defaultQuery);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      widget.viewModel.loadNextPage(widget.defaultQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _offWhite,
      body: Stack(
        children: [
          // ── Blobs decorativos ────────────────────────────────
          Positioned(
            top: -120,
            right: -80,
            child: _Blob(color: _mintPrimary.withOpacity(0.10), size: 320),
          ),
          Positioned(
            top: 300,
            left: -60,
            child: _Blob(color: _warmGold.withOpacity(0.08), size: 220),
          ),

          // ── Grilla de puntos ─────────────────────────────────
          Positioned.fill(
            child: CustomPaint(painter: _DotGridPainter()),
          ),

          // ── Cuerpo principal ─────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: ListenableBuilder(
                    listenable: widget.viewModel,
                    builder: (context, _) => _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // AppBar personalizado
  // ──────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Avatar + saludo
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B5BF7), Color(0xFF3DBF7A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('A',
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w800,
                          fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buenas tardes 👋',
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: _darkText.withOpacity(0.50),
                    ),
                  ),
                  Text(
                    'Catálogo Tinta',
                    style: const TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: _darkText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          // Notificaciones
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: _darkText.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: _darkText, size: 20),
              ),
              Positioned(
                right: 10,
                top: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: _coral, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Cuerpo según estado del viewmodel
  // ──────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final state = widget.viewModel.state;
    final books = widget.viewModel.books;

    if (state == HomeState.loadingInitial) {
      return const Center(
        child: CircularProgressIndicator(color: _mintPrimary),
      );
    }

    if (state == HomeState.error && books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 56, color: _pistachioLight),
            const SizedBox(height: 16),
            Text(
              widget.viewModel.errorMessage ?? 'Error al cargar catálogo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DMSans',
                color: _darkText.withOpacity(0.55),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () =>
                  widget.viewModel.loadInitialCatalog(widget.defaultQuery),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _mintPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded,
                size: 56, color: _pistachioLight),
            const SizedBox(height: 12),
            Text(
              'No se encontraron libros.',
              style: TextStyle(
                fontFamily: 'DMSans',
                color: _darkText.withOpacity(0.45),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // ── Tarjeta de racha ─────────────────────────────────
        SliverToBoxAdapter(child: _buildStreakCard()),

        // ── Sección: Explorar catálogo ───────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Explorar catálogo',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: _darkText,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Ver todo',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _mintPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Lista de libros ──────────────────────────────────
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              if (index == books.length) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: _mintPrimary, strokeWidth: 2.5),
                  ),
                );
              }

              final book = books[index];
              return Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: _BookCard(book: book),
              );
            },
            childCount:
            books.length + (widget.viewModel.hasMoreItems ? 1 : 0),
          ),
        ),

        // ── Espacio inferior para el nav bar ─────────────────
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Tarjeta de racha gamificada
  // ──────────────────────────────────────────────────────────────

  Widget _buildStreakCard() {
    const days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
    const completedDays = [0, 1, 2, 3, 4]; // índices completados (UI)

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A4D2E), Color(0xFF2C6E49)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              children: [
                const Text('🔥',
                    style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Racha de lectura',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Contador de días
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _warmGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '14 días',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF1A2B1F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Burbujas de días
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final done = completedDays.contains(i);
                return Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: done
                            ? _warmGold
                            : Colors.white.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Text('✓',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A2B1F)))
                            : Text(days[i],
                            style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.5))),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // Barra de navegación inferior
  // ──────────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = [
      (icon: Icons.home_rounded, label: 'Home'),
      (icon: Icons.explore_rounded, label: 'Explorar'),
      (icon: Icons.psychology_rounded, label: 'Estudio'),
      (icon: Icons.groups_rounded, label: 'Club'),
      (icon: Icons.person_rounded, label: 'Yo'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _darkText.withOpacity(0.07),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = _selectedNavIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedNavIndex = i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _mintPrimary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].icon,
                        size: 22,
                        color: selected ? _mintPrimary : _darkText.withOpacity(0.35),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? _mintPrimary
                              : _darkText.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de libro individual
// ─────────────────────────────────────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  final dynamic book; // tipo real del proyecto

  static const _darkText   = Color(0xFF1A2B1F);
  static const _mintPrimary = Color(0xFF3DBF7A);
  static const _deepGreen   = Color(0xFF1A4D2E);
  static const _offWhite    = Color(0xFFF2F5EF);

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _darkText.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // TODO: Navegar al detalle del libro
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Portada / thumbnail ──────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: book.thumbnailUrl != null
                      ? Image.network(
                    book.thumbnailUrl!,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _BookPlaceholder(),
                  )
                      : _BookPlaceholder(),
                ),

                const SizedBox(width: 14),

                // ── Metadata ──────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _darkText,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.authors.join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: _darkText.withOpacity(0.50),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Barra de progreso de lectura (UI decorativa)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progreso',
                                style: TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 11,
                                  color: _darkText.withOpacity(0.40),
                                ),
                              ),
                              Text(
                                '0%',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: _mintPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: 0,
                              backgroundColor:
                              _darkText.withOpacity(0.08),
                              valueColor:
                              const AlwaysStoppedAnimation(_mintPrimary),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Flecha ────────────────────────────────────
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: _darkText.withOpacity(0.25)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A4D2E), Color(0xFF3DBF7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('📖', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets de apoyo
// ─────────────────────────────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 28.0;
    final paint = Paint()
      ..color = const Color(0xFF1A2B1F).withOpacity(0.045)
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}