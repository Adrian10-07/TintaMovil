import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/service_locator.dart';
import '../../../user/presentation/viewmodels/user_viewmodel.dart';
import '../../domain/entities/club.dart';
import '../../domain/entities/club_member.dart';
import '../viewmodels/clubs_viewmodel.dart';
import '../components/club_card.dart';
import '../components/invite_dialog.dart';
import 'create_club_view.dart';
import 'club_detail_view.dart';
import 'club_chat_view.dart';

/// Pantalla principal del tab "Club".
///
/// Optimizaciones aplicadas:
/// - Selector en vez de Consumer para rebuilds granulares.
/// - AutomaticKeepAliveClientMixin en los tabs para no recargar al cambiar.
/// - addAutomaticKeepAlives en ListView para reciclar items fuera de vista.
class ClubsListView extends StatefulWidget {
  final bool embedded;
  const ClubsListView({super.key, this.embedded = false});

  @override
  State<ClubsListView> createState() => _ClubsListViewState();
}

class _ClubsListViewState extends State<ClubsListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<ClubsViewModel>().switchTab(
            _tabController.index == 0 ? ClubsTab.explore : ClubsTab.myClubs);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ClubsViewModel>();
      vm.loadPublicClubs();
      vm.loadMyClubs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onClubTap(Club club, {bool isMember = false}) {
    final route = MaterialPageRoute(
      builder: (_) => isMember
          ? ClubChatView(clubId: club.id, clubName: club.name,
          memberCount: club.memberCount)
          : ClubDetailView(clubId: club.id),
    );
    Navigator.push(context, route);
  }

  void _showJoinByCode() {
    showDialog(
      context: context,
      builder: (_) => InviteDialog(
        onJoin: (clubId) async {
          final success = await context.read<ClubsViewModel>().joinClub(clubId);
          if (mounted && success) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Te uniste al club!')));
          }
          return success;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
            child: Row(children: [
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
            ]),
          ),
          TabBar(controller: _tabController, tabs: const [
            Tab(text: 'Explorar'),
            Tab(text: 'Mis Clubes'),
          ]),

          // SearchBar solo cuando tab es Explorar — usa Selector para no rebuild por otros cambios.
          Selector<ClubsViewModel, ClubsTab>(
            selector: (_, vm) => vm.currentTab,
            builder: (_, tab, __) {
              if (tab != ClubsTab.explore) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: SearchBar(
                  hintText: 'Buscar clubes...',
                  leading: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                  onChanged: context.read<ClubsViewModel>().setSearchQuery,
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor:
                  WidgetStatePropertyAll(colorScheme.surfaceContainerHigh),
                ),
              );
            },
          ),

          Expanded(
            child: TabBarView(controller: _tabController, children: [
              _ExploreTab(onClubTap: (c) => _onClubTap(c)),
              _MyClubsTab(onClubTap: (c) => _onClubTap(c, isMember: true)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Explorar (con keep-alive y scroll controller propio) ─────────────────

class _ExploreTab extends StatefulWidget {
  final void Function(Club) onClubTap;
  const _ExploreTab({required this.onClubTap});

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        context.read<ClubsViewModel>().loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin.

    // Selector: solo rebuild cuando la lista de clubs o el state cambia.
    return Selector<ClubsViewModel, ({ClubsState state, List<Club> clubs, bool hasMore})>(
      selector: (_, vm) => (state: vm.state, clubs: vm.filteredPublicClubs, hasMore: vm.hasMorePublic),
      builder: (_, data, __) {
        if (data.state == ClubsState.loading && data.clubs.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (data.state == ClubsState.error && data.clubs.isEmpty) {
          return _Msg(Icons.wifi_off_rounded, 'Error al cargar',
              action: FilledButton.icon(
                  onPressed: context.read<ClubsViewModel>().loadPublicClubs,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintentar')));
        }
        if (data.clubs.isEmpty) {
          return const _Msg(Icons.explore_off_rounded, 'No hay clubes aún.');
        }
        return RefreshIndicator(
          onRefresh: context.read<ClubsViewModel>().loadPublicClubs,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: data.clubs.length + (data.hasMore ? 1 : 0),
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemBuilder: (_, i) {
              if (i == data.clubs.length) {
                return const Padding(padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)));
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClubCard(club: data.clubs[i],
                    onTap: () => widget.onClubTap(data.clubs[i])),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Mis Clubes (con keep-alive) ──────────────────────────────────────────

class _MyClubsTab extends StatefulWidget {
  final void Function(Club) onClubTap;
  const _MyClubsTab({required this.onClubTap});

  @override
  State<_MyClubsTab> createState() => _MyClubsTabState();
}

class _MyClubsTabState extends State<_MyClubsTab>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Selector<ClubsViewModel, ({ClubsState state, List<ClubMember> memberships})>(
      selector: (_, vm) => (state: vm.state, memberships: vm.sortedMemberships),
      builder: (_, data, __) {
        if (data.state == ClubsState.loading && data.memberships.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (data.memberships.isEmpty) {
          return const _Msg(Icons.group_off_rounded, 'Aún no perteneces a ningún club.');
        }
        return RefreshIndicator(
          onRefresh: context.read<ClubsViewModel>().loadMyClubs,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            itemCount: data.memberships.length,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            itemBuilder: (_, i) {
              final m = data.memberships[i];
              // Selector anidado: solo rebuild este item cuando su club cambia.
              return Selector<ClubsViewModel, Club?>(
                selector: (_, vm) => vm.getMyClub(m.clubId),
                builder: (_, club, __) {
                  if (club == null) {
                    return const Padding(padding: EdgeInsets.only(bottom: 8),
                        child: Card(child: ListTile(
                            leading: CircularProgressIndicator(strokeWidth: 2),
                            title: Text('Cargando...'))));
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ClubCard(club: club, memberRole: m.role,
                        onTap: () => widget.onClubTap(club)),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

// ── Auxiliar ──────────────────────────────────────────────────────────────

class _Msg extends StatelessWidget {
  final IconData icon; final String message; final Widget? action;
  const _Msg(this.icon, this.message, {this.action});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 56, color: cs.primaryContainer),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      if (action != null) ...[const SizedBox(height: 20), action!],
    ],
    )));
  }
}