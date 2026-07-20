import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/clubs_viewmodel.dart';
import '../components/club_card.dart';
import '../components/invite_dialog.dart';
import 'create_club_view.dart';
import 'club_detail_view.dart';

/// Pantalla principal del tab "Club" en la navegación inferior.
///
/// Dos tabs internos:
/// - Explorar: lista paginada de clubes públicos con búsqueda.
/// - Mis Clubes: clubes a los que el usuario pertenece.
class ClubsListView extends StatefulWidget {
  const ClubsListView({super.key});

  @override
  State<ClubsListView> createState() => _ClubsListViewState();
}

class _ClubsListViewState extends State<ClubsListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    // Carga inicial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClubsViewModel>().loadPublicClubs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final vm = context.read<ClubsViewModel>();
      vm.switchTab(
        _tabController.index == 0 ? ClubsTab.explore : ClubsTab.myClubs,
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ClubsViewModel>().loadNextPage();
    }
  }

  void _navigateToDetail(String clubId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ClubDetailView(clubId: clubId)),
    );
  }

  void _navigateToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateClubView()),
    );
  }

  void _showJoinByCode() {
    showDialog(
      context: context,
      builder: (_) => InviteDialog(
        onJoin: (code) async {
          final vm = context.read<ClubsViewModel>();
          final success = await vm.joinWithCode(code);
          if (mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Te uniste al club!')),
            );
          }
          return success;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text('Clubes', style: textTheme.headlineMedium),
              ),
              IconButton(
                onPressed: _showJoinByCode,
                icon: const Icon(Icons.qr_code_rounded),
                tooltip: 'Unirse con código',
              ),
              FilledButton.icon(
                onPressed: _navigateToCreate,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Crear'),
              ),
            ],
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Explorar'),
            Tab(text: 'Mis Clubes'),
          ],
        ),

        // Search (solo en Explorar)
        Consumer<ClubsViewModel>(
          builder: (_, vm, __) {
            if (vm.currentTab != ClubsTab.explore) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: SearchBar(
                hintText: 'Buscar clubes...',
                leading: Icon(Icons.search,
                    color: colorScheme.onSurfaceVariant),
                onChanged: vm.setSearchQuery,
                elevation: WidgetStatePropertyAll(0),
                backgroundColor:
                    WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
              ),
            );
          },
        ),

        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ExploreTab(
                scrollController: _scrollController,
                onClubTap: _navigateToDetail,
              ),
              _MyClubsTab(onClubTap: _navigateToDetail),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tab: Explorar ─────────────────────────────────────────────────────────

class _ExploreTab extends StatelessWidget {
  final ScrollController scrollController;
  final void Function(String clubId) onClubTap;

  const _ExploreTab({
    required this.scrollController,
    required this.onClubTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ClubsViewModel>(
      builder: (_, vm, __) {
        if (vm.state == ClubsState.loading && vm.publicClubs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.state == ClubsState.error && vm.publicClubs.isEmpty) {
          return _ErrorWidget(
            message: vm.errorMessage,
            onRetry: vm.loadPublicClubs,
          );
        }

        final clubs = vm.filteredPublicClubs;

        if (clubs.isEmpty) {
          return _EmptyWidget(
            icon: Icons.explore_off_rounded,
            message: vm.searchQuery.isEmpty
                ? 'No hay clubes disponibles aún.'
                : 'No se encontraron clubes para "${vm.searchQuery}".',
          );
        }

        return RefreshIndicator(
          onRefresh: vm.loadPublicClubs,
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: clubs.length + (vm.hasMorePublic ? 1 : 0),
            itemBuilder: (_, i) {
              if (i == clubs.length) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5)),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClubCard(
                  club: clubs[i],
                  onTap: () => onClubTap(clubs[i].id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Tab: Mis Clubes ───────────────────────────────────────────────────────

class _MyClubsTab extends StatelessWidget {
  final void Function(String clubId) onClubTap;

  const _MyClubsTab({required this.onClubTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClubsViewModel>(
      builder: (_, vm, __) {
        if (vm.state == ClubsState.loading && vm.myMemberships.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vm.myMemberships.isEmpty) {
          return _EmptyWidget(
            icon: Icons.group_off_rounded,
            message: 'Aún no perteneces a ningún club.\n'
                'Explora o crea uno nuevo.',
          );
        }

        return RefreshIndicator(
          onRefresh: vm.loadMyClubs,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: vm.myMemberships.length,
            itemBuilder: (_, i) {
              final membership = vm.myMemberships[i];
              final club = vm.getMyClub(membership.clubId);

              if (club == null) {
                // Todavía cargando detalles del club.
                return const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      leading: CircularProgressIndicator(strokeWidth: 2),
                      title: Text('Cargando...'),
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClubCard(
                  club: club,
                  memberRole: membership.role,
                  onTap: () => onClubTap(club.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────

class _ErrorWidget extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  const _ErrorWidget({this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              size: 56, color: colorScheme.primaryContainer),
          const SizedBox(height: 16),
          Text(
            message ?? 'Error al cargar clubes',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.55),
                ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _EmptyWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyWidget({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: colorScheme.primaryContainer),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.45),
                ),
          ),
        ],
      ),
    );
  }
}
