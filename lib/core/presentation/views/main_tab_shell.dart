import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../di/service_locator.dart';
import '../../../features/home/presentation/views/home_view.dart';
import '../../../features/home/presentation/viewmodels/home_viewmodel.dart';
import '../../../features/home/presentation/components/tinta_bottom_nav.dart';
import '../../../features/recommendations/presentation/views/recommendations_view.dart';
import '../../../features/recommendations/presentation/views/upload_book_view.dart';
import '../../../features/user/presentation/views/user_view.dart';
import '../../../features/user/presentation/viewmodels/user_viewmodel.dart';
import '../../../features/clubs/presentation/views/clubs_list_view.dart';
import '../../../features/clubs/data/services/club_notification_service.dart';

/// Shell raíz de la app tras el login.
///
/// Contiene la barra inferior PERMANENTE (Home / Explorar / Estudio /
/// Club / Yo) y cambia entre pestañas con un [IndexedStack] en vez de
/// apilar rutas con Navigator — por eso la barra nunca desaparece al
/// cambiar de pestaña, no hace falta botón "back" entre ellas, y cada
/// pestaña conserva su estado (scroll, formularios, etc.) al volver.
///
/// La barra SÍ desaparece cuando se abre una pantalla de detalle real
/// (lector de EPUB, visor de PDF, detalle de libro) porque esas se abren
/// con Navigator.push por ENCIMA de este shell, cubriéndolo entero.
class MainTabShell extends StatefulWidget {
  const MainTabShell({Key? key}) : super(key: key);

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  int _index = 0;
  late final HomeViewModel _homeViewModel;
  late final ClubNotificationService _notifService;

  @override
  void initState() {
    super.initState();
    _homeViewModel = sl<HomeViewModel>();
    _notifService = sl<ClubNotificationService>();

    // Iniciar polling de notificaciones cuando el userId esté disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<UserViewModel>().profile?.id;
      if (userId != null) {
        _notifService.initialize(userId);
        _notifService.startPolling();
      }
    });
  }

  @override
  void dispose() {
    _notifService.stopPolling();
    super.dispose();
  }

  void _onTap(int index) {
    // Si entra al tab de clubs, marcar como visto y refrescar badge.
    if (index == 3) {
      _notifService.refresh();
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserViewModel>().profile?.id ?? '';

    final tabs = <Widget>[
      HomeView(viewModel: _homeViewModel, defaultQuery: '', embedded: true),
      const RecommendationsView(embedded: true),
      UploadBookView(userId: userId, embedded: true),
      const ClubsListView(embedded: true),
      const UserView(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: ListenableBuilder(
        listenable: _notifService,
        builder: (_, __) => TintaBottomNav(
          currentIndex: _index,
          onTap: _onTap,
          clubBadgeCount: _notifService.unreadCount,
        ),
      ),
    );
  }
}