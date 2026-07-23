import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../home/presentation/components/tinta_bottom_nav.dart';
import '../../../recommendations/presentation/views/recommendations_view.dart';
import '../../../recommendations/presentation/views/upload_book_view.dart';
import '../../../../core/di/service_locator.dart';
import '../../../user/presentation/viewmodels/user_viewmodel.dart';
import '../../domain/entities/club.dart';
import '../viewmodels/clubs_viewmodel.dart';
import '../components/club_card.dart';
import '../components/invite_dialog.dart';
import 'create_club_view.dart';
import 'club_detail_view.dart';
import 'club_chat_view.dart';

/// Pantalla principal del tab "Club" con navbar global.
class ClubsListView extends StatefulWidget {
  /// Cuando es true, se usa como pestaña dentro de [MainTabShell]:
  /// no dibuja su propio Scaffold ni barra inferior.
  final bool embedded;

  const ClubsListView({super.key, this.embedded = false});

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ClubsViewModel>();
      vm.loadPublicClubs();
      vm.loadMyClubs();
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
      context.read<ClubsViewModel>().switchTab(
          _tabController.index == 0 ? ClubsTab.explore : ClubsTab.myClubs);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ClubsViewModel>().loadNextPage();
    }
  }

  /// Mis clubes → directo al chat. Explorar → al detalle para unirse.
  void _onClubTap(Club club, {bool isMember = false}) {
    if (isMember) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClubChatView(
            clubId: club.id,
            clubName: club.name,
            memberCount: club.memberCount,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClubDetailView(clubId: club.id)),
      );
    }
  }

  void _showJoinByCode() {
    showDialog(
      context: context,
      builder: (_) => InviteDialog(
        onJoin: (clubId) async {
          final vm = context.read<ClubsViewModel>();
          final success = await vm.joinClub(clubId);
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

  void _onNavTap(int index) {
    switch (index) {
      case 0: Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false); break;
      case 1: Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommendationsView())); break;
      case 2: _navigateToStudy(); break;
      case 3: break; // ya aquí
      case 4: Navigator.pushNamed(context, '/user'); break;
    }
  }

  Future<void> _navigateToStudy() async {
    final userVm = sl<UserViewModel>();
    if (userVm.profile == null) await userVm.loadProfile();
    final userId = userVm.profile?.id;
    if (userId == null || !mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => UploadBookView(userId: userId)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final content = SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(
              children: [
                Expanded(child: Text('Clubes', style: textTheme.headlineMedium)),
                IconButton(
                  onPressed: _showJoinByCode,
                  icon: const Icon(Icons.qr_code_rounded),
                  tooltip: 'Unirse con código',
                ),
                const SizedBox(width: 4),
                FilledButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreateClubView())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Crear'),
                ),
              ],
            ),
          ),
          TabBar(controller: _tabController, tabs: const [
            Tab(text: 'Explorar'),
            Tab(text: 'Mis Clubes'),
          ]),
          Consumer<ClubsViewModel>(
            builder: (_, vm, __) {
              if (vm.currentTab != ClubsTab.explore) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: SearchBar(
                  hintText: 'Buscar clubes...',
                  leading: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                  onChanged: vm.setSearchQuery,
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
                ),
              );
            },
          ),
          Expanded(
            child: TabBarView(controller: _tabController, children: [
              _ExploreTab(scrollController: _scrollController, onClubTap: (c) => _onClubTap(c)),
              _MyClubsTab(onClubTap: (c) => _onClubTap(c, isMember: true)),
            ]),
          ),
        ],
      ),
    );

    // Como pestaña del shell: sin Scaffold ni bottomNavigationBar propios.
    if (widget.embedded) return content;

    // Uso independiente (fuera del shell).
    return Scaffold(
      body: content,
      bottomNavigationBar: TintaBottomNav(currentIndex: 3, onTap: _onNavTap),
    );
  }
}

class _ExploreTab extends StatelessWidget {
  final ScrollController scrollController;
  final void Function(Club) onClubTap;
  const _ExploreTab({required this.scrollController, required this.onClubTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClubsViewModel>(builder: (_, vm, __) {
      if (vm.state == ClubsState.loading && vm.publicClubs.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (vm.state == ClubsState.error && vm.publicClubs.isEmpty) {
        return _Msg(Icons.wifi_off_rounded, vm.errorMessage ?? 'Error',
            action: FilledButton.icon(onPressed: vm.loadPublicClubs,
                icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Reintentar')));
      }
      final clubs = vm.filteredPublicClubs;
      if (clubs.isEmpty) {
        return _Msg(Icons.explore_off_rounded,
            vm.searchQuery.isEmpty ? 'No hay clubes aún.' : 'Sin resultados.');
      }
      return RefreshIndicator(
        onRefresh: vm.loadPublicClubs,
        child: ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: clubs.length + (vm.hasMorePublic ? 1 : 0),
          itemBuilder: (_, i) {
            if (i == clubs.length) {
              return const Padding(padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)));
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClubCard(club: clubs[i], onTap: () => onClubTap(clubs[i])),
            );
          },
        ),
      );
    });
  }
}

class _MyClubsTab extends StatelessWidget {
  final void Function(Club) onClubTap;
  const _MyClubsTab({required this.onClubTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClubsViewModel>(builder: (_, vm, __) {
      if (vm.state == ClubsState.loading && vm.myMemberships.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (vm.myMemberships.isEmpty) {
        return const _Msg(Icons.group_off_rounded, 'Aún no perteneces a ningún club.');
      }
      return RefreshIndicator(
        onRefresh: vm.loadMyClubs,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: vm.myMemberships.length,
          itemBuilder: (_, i) {
            final m = vm.myMemberships[i];
            final club = vm.getMyClub(m.clubId);
            if (club == null) {
              return const Padding(padding: EdgeInsets.only(bottom: 8),
                  child: Card(child: ListTile(leading: CircularProgressIndicator(strokeWidth: 2), title: Text('Cargando...'))));
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ClubCard(club: club, memberRole: m.role, onTap: () => onClubTap(club)),
            );
          },
        ),
      );
    });
  }
}

class _Msg extends StatelessWidget {
  final IconData icon; final String message; final Widget? action;
  const _Msg(this.icon, this.message, {this.action});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: cs.primaryContainer),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    )));
  }
}